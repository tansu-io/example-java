#!/usr/bin/env bats

@test "create topic test" {
    run docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server tansu:9092 --config cleanup.policy=compact --partitions=3 --replication-factor=1 --create --topic test
    [ "${lines[0]}" = "Created topic test." ]
}

@test "duplicate topic test" {
    run docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server tansu:9092 --config cleanup.policy=compact --partitions=3 --replication-factor=1 --create --topic test
    [ "${lines[0]}" = "Error while executing topic command : Topic with this name already exists." ]
}
