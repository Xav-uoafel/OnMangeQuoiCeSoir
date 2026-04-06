class PantryScansController < ApplicationController
  before_action :authenticate_user!

  def new
    @pantry_scan = PantryScan.new
  end

  def create
    @pantry_scan = current_user.pantry_scans.build(pantry_scan_params)

    if @pantry_scan.save
      PantryScanJob.perform_later(@pantry_scan.id)
      redirect_to @pantry_scan, notice: 'Scan lance ! Analyse des photos en cours...'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @pantry_scan = current_user.pantry_scans.find(params[:id])
    @detected_items = current_user.pantry_items.where(source: 'photo_scan', detected_on: @pantry_scan.created_at.to_date)
  end

  private

  def pantry_scan_params
    params.require(:pantry_scan).permit(:label, photos: [])
  end
end
