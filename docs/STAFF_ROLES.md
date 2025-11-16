# Staff Roles

## Defined Roles

| Key                   | English             | French                 |
| --------------------- | ------------------- | ---------------------- |
| `taikai_admin`        | Administrator       | Administrateur         |
| `dojo_admin`          | Dojo Administrator  | Administrateur de club |
| `chairman`            | Chairman            | Directeur du tournoi   |
| `marking_referee`     | Marking Referee     | Enregistreur           |
| `shajo_referee`       | Shajo Referee       | Juge de Shajo          |
| `yatori`              | Yatori              | Yatori                 |
| `target_referee`      | Target Referee      | Juge de Cible          |
| `operations_chairman` | Operations Chairman | Responsable Logistique |

## Transition Constraints

| From State   | To State | Taikai Types | Required Staff Roles                          |
| ------------ | -------- | ------------ | --------------------------------------------- |
| Registration | Marking  | All          | `chairman`, `shajo_referee`, `target_referee` |
