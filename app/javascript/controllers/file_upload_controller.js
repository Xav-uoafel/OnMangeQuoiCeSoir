import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "summary", "submit"]
  static values = {
    allowedTypes: Array,
    maxFiles: Number,
    maxFileSize: Number,
    maxTotalSize: Number
  }

  connect() {
    this.update()
  }

  update() {
    const files = Array.from(this.inputTarget.files)
    const error = this.validationError(files)

    this.inputTarget.setCustomValidity(error || "")
    this.inputTarget.setAttribute("aria-invalid", error ? "true" : "false")
    this.submitTarget.disabled = files.length === 0 || Boolean(error)

    if (error) {
      this.summaryTarget.textContent = error
    } else if (files.length === 0) {
      this.summaryTarget.textContent = "Aucune photo sélectionnée."
    } else {
      const totalSize = files.reduce((sum, file) => sum + file.size, 0)
      this.summaryTarget.textContent = `${files.length} photo${files.length > 1 ? "s" : ""} prête${files.length > 1 ? "s" : ""} à analyser (${this.formatBytes(totalSize)}).`
    }
  }

  validationError(files) {
    if (files.length > this.maxFilesValue) {
      return `Sélectionnez ${this.maxFilesValue} photos maximum.`
    }

    const unsupported = files.find((file) => !this.allowedTypesValue.includes(file.type))
    if (unsupported) {
      return `${unsupported.name} n’est pas au format JPG, PNG ou WebP.`
    }

    const oversized = files.find((file) => file.size > this.maxFileSizeValue)
    if (oversized) {
      return `${oversized.name} dépasse la limite de ${this.formatBytes(this.maxFileSizeValue)}.`
    }

    const totalSize = files.reduce((sum, file) => sum + file.size, 0)
    if (totalSize > this.maxTotalSizeValue) {
      return `L’ensemble des photos dépasse la limite de ${this.formatBytes(this.maxTotalSizeValue)}.`
    }

    return null
  }

  formatBytes(bytes) {
    if (bytes < 1024 * 1024) return `${Math.max(1, Math.round(bytes / 1024))} Ko`

    return `${(bytes / (1024 * 1024)).toLocaleString("fr-FR", { maximumFractionDigits: 1 })} Mo`
  }
}
