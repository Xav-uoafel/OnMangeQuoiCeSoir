(foregroundSelector, backgroundSelector) => {
  const foregroundElement = document.querySelector(foregroundSelector)
  const backgroundElement = document.querySelector(backgroundSelector)
  const foregroundCss = getComputedStyle(foregroundElement).color
  const canvas = document.createElement("canvas")
  canvas.width = 1
  canvas.height = 1

  const context = canvas.getContext("2d", { willReadFrequently: true })
  const parseColor = (color) => {
    context.clearRect(0, 0, 1, 1)
    context.fillStyle = color
    context.fillRect(0, 0, 1, 1)
    const [red, green, blue, alpha] = context.getImageData(0, 0, 1, 1).data

    return { red, green, blue, alpha: alpha / 255 }
  }
  const composite = (foreground, background) => {
    const alpha = foreground.alpha + background.alpha * (1 - foreground.alpha)
    if (alpha === 0) return { red: 0, green: 0, blue: 0, alpha: 0 }

    return {
      red: (
        foreground.red * foreground.alpha +
        background.red * background.alpha * (1 - foreground.alpha)
      ) / alpha,
      green: (
        foreground.green * foreground.alpha +
        background.green * background.alpha * (1 - foreground.alpha)
      ) / alpha,
      blue: (
        foreground.blue * foreground.alpha +
        background.blue * background.alpha * (1 - foreground.alpha)
      ) / alpha,
      alpha
    }
  }

  const backgroundLayers = []
  let currentElement = backgroundElement
  while (currentElement) {
    backgroundLayers.push(parseColor(getComputedStyle(currentElement).backgroundColor))
    currentElement = currentElement.parentElement
  }

  const background = backgroundLayers.reverse().reduce(
    (result, layer) => composite(layer, result),
    { red: 255, green: 255, blue: 255, alpha: 1 }
  )
  const foreground = composite(parseColor(foregroundCss), background)
  const luminance = (color) => [color.red, color.green, color.blue].map((value) => {
    const channel = value / 255
    return channel <= 0.04045 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4)
  }).reduce((sum, value, index) => sum + value * [0.2126, 0.7152, 0.0722][index], 0)
  const foregroundLuminance = luminance(foreground)
  const backgroundLuminance = luminance(background)
  const ratio = (Math.max(foregroundLuminance, backgroundLuminance) + 0.05) /
    (Math.min(foregroundLuminance, backgroundLuminance) + 0.05)
  const rgb = (color) => {
    return `rgb(${Math.round(color.red)}, ${Math.round(color.green)}, ${Math.round(color.blue)})`
  }

  return { ratio, foreground: rgb(foreground), background: rgb(background) }
}
