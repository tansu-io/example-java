#!/usr/bin/env bats

NETWORK=$(docker compose ps -a --format '{{.Networks}}\t{{.Service}}'|grep tansu|cut -f1)
echo "network: $NETWORK"

IPADDR=$(docker inspect --format "{{index .NetworkSettings.Networks \""${NETWORK}"\" \"IPAddress\"}}" "$(docker compose ps -a --format '{{.ID}}\t{{.Service}}'|grep tansu|cut -f1)")
echo "ipaddr: $IPADDR"

@test "create topic test" {
    run docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server "$IPADDR:9092" --config cleanup.policy=compact --partitions=3 --replication-factor=1 --create --topic test
    [ "${lines[0]}" = "Created topic test." ]
}

@test "duplicate topic test" {
    run docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server "$IPADDR:9092" --config cleanup.policy=compact --partitions=3 --replication-factor=1 --create --topic test
    [ "${lines[0]}" = "Error while executing topic command : Topic with this name already exists." ]
}
