// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "./application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import RatingController from "./rating_controller"

eagerLoadControllersFrom("controllers", application)
application.register("rating", RatingController)
