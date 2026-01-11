// Stub for stimulus loading - controllers are loaded via importmap pin_all_from
export function eagerLoadControllersFrom(path, application) {
  // Controllers are automatically registered via importmap's pin_all_from
  // This function is kept for compatibility but does nothing
  // The actual loading happens through config/importmap.rb: pin_all_from "app/javascript/controllers"
}
