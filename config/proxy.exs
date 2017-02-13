use Mix.Config

config :proxy, :routes, [
  %{path: "/is/auth/register", port: 7070, host: "IS_HOST", auth: false},
  %{path: "/is/auth", port: 7070, host: "IS_HOST", auth: false},
  %{path: "/is/user-info", port: 7070, host: "IS_HOST", auth: true},
  %{path: "/is/users/{id}", port: 7070, host: "IS_HOST", auth: true},
  %{path: "/is/enrollments", port: 7070, host: "IS_HOST", auth: true},
  %{path: "/is/enrollments/{id}", port: 7070, host: "IS_HOST", auth: true},
  %{path: "/is/users", port: 7070, host: "IS_HOST", auth: true},
  %{path: "/ps/{id}/form/last", port: 8080, host: "PS_HOST", auth: true},
  %{path: "/ps/tasks", port: 8080, host: "PS_HOST", auth: true},
  %{path: "/ps/tasks/{id}", port: 8080, host: "PS_HOST", auth: true},
  %{path: "/ps/tasks/{id}/submit", port: 8080, host: "PS_HOST", auth: true},
  %{path: "/ps/forms", port: 8080, host: "PS_HOST", auth: true},
  %{path: "/ps/forms/{id}", port: 8080, host: "PS_HOST", auth: true},
  %{path: "/ts/transactions", port: 8889, host: "TS_HOST", auth: true},
  %{path: "/ts/transactions/balance", port: 8889, host: "TS_HOST", auth: true},
  %{path: "/ts/transactions/sum", port: 8889, host: "TS_HOST", auth: true},
  %{path: "/ts/users", port: 8889, host: "TS_HOST", auth: true},
]
