// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application"

// Import all controllers
import DragController from "controllers/drag_controller"
import DragTeamsController from "controllers/drag_teams_controller"
import FileUploadController from "controllers/file_upload_controller"
import ParticipantCompleteController from "controllers/participant_complete_controller"

// Register controllers
application.register("drag", DragController)
application.register("drag-teams", DragTeamsController)
application.register("file-upload", FileUploadController)
application.register("participant-complete", ParticipantCompleteController)


