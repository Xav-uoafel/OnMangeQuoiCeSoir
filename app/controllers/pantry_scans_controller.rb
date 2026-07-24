class PantryScansController < ApplicationController
  before_action :authenticate_user!
  database_rate_limit to: 10, within: 1.hour, scope: "pantry_scan", only: %i[create retry_analysis]

  def new
    @pantry_scan = PantryScan.new
  end

  def create
    @pantry_scan = current_user.pantry_scans.build(pantry_scan_params)

    if @pantry_scan.save
      if enqueue_analysis(@pantry_scan)
        redirect_to @pantry_scan, notice: 'Scan lancé ! Analyse des photos en cours…'
      else
        redirect_to @pantry_scan, alert: @pantry_scan.analysis_error_message
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @pantry_scan = current_user.pantry_scans.find(params[:id])
    @detected_items = detected_items_for(@pantry_scan)
  end

  def confirm
    @pantry_scan = current_user.pantry_scans.find(params[:id])

    unless @pantry_scan.pending_review?
      redirect_to @pantry_scan, alert: "Ce scan ne peut pas être validé."
      return
    end

    selected_items = selected_detected_items
    reconciler = PantryStockReconciler.new(current_user)
    pantry_items = selected_items.map do |item|
      reconciler.upsert!(
        item.merge(
          detected_on: @pantry_scan.created_at.to_date,
          source: 'photo_scan',
          pantry_scan: @pantry_scan
        )
      )
    end

    @pantry_scan.update!(
      status: 'completed',
      items_detected: pantry_items.map(&:id).uniq.size
    )

    added_count = pantry_items.map(&:id).uniq.size
    redirect_to @pantry_scan, notice: "#{added_count} #{added_count > 1 ? 'ingrédients ajoutés' : 'ingrédient ajouté'} au stock."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @pantry_scan, alert: e.record.errors.full_messages.to_sentence
  end

  def retry_analysis
    @pantry_scan = current_user.pantry_scans.find(params[:id])

    unless @pantry_scan.analysis_retryable?
      redirect_to @pantry_scan, alert: "Cette analyse est déjà en cours ou a été traitée."
      return
    end

    if enqueue_analysis(@pantry_scan)
      redirect_to @pantry_scan, notice: "Analyse relancée avec les photos existantes."
    else
      redirect_to @pantry_scan, alert: @pantry_scan.analysis_error_message
    end
  end

  def discard
    @pantry_scan = current_user.pantry_scans.find(params[:id])

    unless @pantry_scan.pending_review?
      redirect_to @pantry_scan, alert: "Ce scan ne peut pas être ignoré."
      return
    end

    @pantry_scan.update!(status: 'discarded', items_detected: 0, detected_items: [])

    redirect_to pantry_items_path, notice: "Scan ignoré. Aucun ingrédient ajouté au stock."
  end

  private

  def pantry_scan_params
    params.require(:pantry_scan).permit(:label, photos: [])
  end

  def detected_items_for(scan)
    return scan.detected_items if scan.pending_review?

    scan.pantry_items.order(:name)
  end

  def selected_detected_items
    params.fetch(:detected_items, {}).values.filter_map do |raw_item|
      next unless raw_item[:selected] == "1"

      raw_item.permit(:name, :category, :quantity_text).to_h.symbolize_keys
    end
  end

  def enqueue_analysis(scan)
    token = scan.start_analysis!
    job = PantryScanJob.perform_later(scan.id, token)
    return true if job.successfully_enqueued?

    scan.fail_analysis!(token, code: "queue_unavailable")
    false
  rescue ActiveJob::EnqueueError => e
    Rails.error.report(e, handled: true)
    scan.fail_analysis!(token, code: "queue_unavailable") if token
    false
  end
end
