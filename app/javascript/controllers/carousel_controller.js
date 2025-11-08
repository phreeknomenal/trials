import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["slide", "dot"];
  static values = { interval: Number };

  connect() {
    this.currentIndex = 0;
    this.showSlide(this.currentIndex);
    this.startAutoSlide();
  }

  startAutoSlide() {
    this.stopAutoSlide();
    this.timer = setInterval(
      () => this.nextSlide(),
      this.intervalValue || 3000,
    );
  }

  stopAutoSlide() {
    if (this.timer) clearInterval(this.timer);
  }

  nextSlide() {
    this.showSlide((this.currentIndex + 1) % this.slideTargets.length);
  }

  goToSlide(event) {
    const index = this.dotTargets.indexOf(event.currentTarget);
    this.showSlide(index);
    this.startAutoSlide();
  }

  showSlide(index) {
    this.slideTargets.forEach((slide, i) => {
      slide.style.display = i === index ? "block" : "none";
    });

    this.dotTargets.forEach((dot, i) => {
      dot.classList.toggle("active", i === index);
    });

    this.currentIndex = index;
  }
}
