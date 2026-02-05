export function showDialog(selector) {
  const dialog = document.querySelector(selector)
  if (dialog) {
    dialog.showModal()
    return
  }
  console.warn(`${selector} is not found!`)
}