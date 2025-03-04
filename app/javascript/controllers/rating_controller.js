import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star", "input"]

  connect() {
    console.log("Rating controller connected")
    console.log("Stars found:", this.starTargets.length)
    this.setInitialRating()
  }

  setInitialRating() {
    const currentRating = this.element.dataset.rating
    if (currentRating) {
      this.colorStars(currentRating - 1)
    }
  }

  highlight(event) {
    console.log("highlight called")
    const index = event.currentTarget.dataset.index
    this.colorStars(index)
  }

  reset() {
    const selectedRating = this.element.querySelector('input[type="radio"]:checked')
    if (selectedRating) {
      this.colorStars(selectedRating.value - 1)
    } else {
      this.starTargets.forEach(star => star.classList.remove('text-yellow-400'))
    }
  }

  colorStars(index) {
    this.starTargets.forEach((star, i) => {
      if (i <= index) {
        star.classList.add('text-yellow-400')
        star.classList.remove('text-gray-300')
      } else {
        star.classList.remove('text-yellow-400')
        star.classList.add('text-gray-300')
      }
    })
  }
} 