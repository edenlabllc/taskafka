use Mix.Config

config :taskafka, :mongo, url: "mongodb://localhost:27017/taskafka_test"
config :taskafka, :idle, false

config :kaffe,
  kafka_mod: :brod
