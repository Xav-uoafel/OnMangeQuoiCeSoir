import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "feedback"]

  async copy() {
    try {
      await navigator.clipboard.writeText(this.sourceTarget.textContent.trim())
      this.feedbackTarget.textContent = "Code copié"
    } catch (_error) {
      this.feedbackTarget.textContent = "Copie impossible : sélectionnez le code manuellement."
    }
  }
}
