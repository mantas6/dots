- [x] tgl: decoding response: json: cannot unmarshal object into Go value of type []api.Task (tgl update error)
      Fixed: the workspace tasks endpoint returns a {data,total_count,per_page}
      envelope, not a bare array; api.Tasks now walks that envelope.
- [x] there is no way to list all tasks in cli
      Fixed: added `tgl tasks` (with --all/--json) to list the cached catalog.
- [x] from entries the task title is missing
      Fixed: `tgl pull` now self-heals the catalog from the meta=true
      project_name/task_name, so entry titles resolve even before `tgl update`.
