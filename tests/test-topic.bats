#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

@test "delete non-existing topic" {
    run -1 docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server tansu:9092 --delete --topic test
}

@test "create topic" {
    run docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server tansu:9092 --config cleanup.policy=compact --partitions=3 --replication-factor=1 --create --topic test
    [ "${lines[0]}" = "Created topic test." ]
}

@test "list topics" {
    run docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server tansu:9092 --list
    [ "${lines[0]}" = "test" ]
}

@test "create duplicate topic" {
    run docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server tansu:9092 --config cleanup.policy=compact --partitions=3 --replication-factor=1 --create --topic test
    [ "${lines[0]}" = "Error while executing topic command : Topic with this name already exists." ]
}

@test "describe topic" {
    run docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server tansu:9092 --describe --topic test
    [ "${lines[1]}" = "	Topic: test	Partition: 0	Leader: 111	Replicas: 111	Isr: 111	Adding Replicas: 	Removing Replicas: 	Elr: N/A	LastKnownElr: N/A" ]
    [ "${lines[2]}" = "	Topic: test	Partition: 1	Leader: 111	Replicas: 111	Isr: 111	Adding Replicas: 	Removing Replicas: 	Elr: N/A	LastKnownElr: N/A" ]
    [ "${lines[3]}" = "	Topic: test	Partition: 2	Leader: 111	Replicas: 111	Isr: 111	Adding Replicas: 	Removing Replicas: 	Elr: N/A	LastKnownElr: N/A" ]
}

@test "before produce, earliest offsets" {
    run docker compose exec kafka /opt/kafka/bin/kafka-get-offsets.sh --bootstrap-server tansu:9092 --topic test --time earliest
    [ "${lines[0]}" = "test:0:0" ]
    [ "${lines[1]}" = "test:1:0" ]
    [ "${lines[2]}" = "test:2:0" ]
}

@test "before produce, latest offsets" {
    run docker compose exec kafka /opt/kafka/bin/kafka-get-offsets.sh --bootstrap-server tansu:9092 --topic test --time latest
    [ "${lines[0]}" = "test:0:0" ]
    [ "${lines[1]}" = "test:1:0" ]
    [ "${lines[2]}" = "test:2:0" ]
}

@test "produce" {
    run bash -c "echo 'h1:pqr,h2:jkl,h3:uio	qwerty	poiuy' | docker compose exec --no-TTY kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server tansu:9092 --topic test --property parse.headers=true --property parse.key=true"
    run bash -c "echo 'h1:def,h2:lmn,h3:xyz	asdfgh	lkj' | docker compose exec --no-TTY kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server tansu:9092 --topic test --property parse.headers=true --property parse.key=true"
    run bash -c "echo 'h1:stu,h2:fgh,h3:ijk	zxcvbn	mnbvc' | docker compose exec --no-TTY kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server tansu:9092 --topic test --property parse.headers=true --property parse.key=true"
}

@test "after produce, earliest offsets" {
    run docker compose exec kafka /opt/kafka/bin/kafka-get-offsets.sh --bootstrap-server tansu:9092 --topic test --time earliest
    [ "${lines[0]}" = "test:0:0" ]
    [ "${lines[1]}" = "test:1:0" ]
    [ "${lines[2]}" = "test:2:0" ]
}

@test "after produce, latest offsets" {
    run docker compose exec kafka /opt/kafka/bin/kafka-get-offsets.sh --bootstrap-server tansu:9092 --topic test --time latest
    [ "${lines[0]}" = "test:0:1" ]
    [ "${lines[1]}" = "test:1:1" ]
    [ "${lines[2]}" = "test:2:1" ]
}

@test "before consume, consumer-group-describe" {
    run docker compose exec kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server tansu:9092 --group test-consumer-group --describe
    [ "${lines[0]}" = "Consumer group 'test-consumer-group' has no active members." ]
}

@test "consume" {
    run docker compose exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server tansu:9092 --timeout-ms 30000 --consumer-property fetch.max.wait.ms=15000 --group test-consumer-group --topic test --from-beginning --property print.key=true --property print.offset=true --property print.partition=true --property print.headers=true --property print.value=true
    [ "${lines[0]}" = "Partition:1	Offset:0	h1:stu,h2:fgh,h3:ijk	zxcvbn	mnbvc" ]
    [ "${lines[1]}" = "Partition:0	Offset:0	h1:pqr,h2:jkl,h3:uio	qwerty	poiuy" ]
    [ "${lines[2]}" = "Partition:2	Offset:0	h1:def,h2:lmn,h3:xyz	asdfgh	lkj" ]
    [ "${lines[5]}" = "Processed a total of 3 messages" ]
}

@test "after consume, consumer-group-describe" {
    run docker compose exec kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server tansu:9092 --group test-consumer-group --describe
    [ "${lines[0]}" = "Consumer group 'test-consumer-group' has no active members." ]
    [ "${lines[1]}" = "GROUP               TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID" ]
    [ "${lines[2]}" = "test-consumer-group test            1          1               1               0               -               -               -" ]
    [ "${lines[3]}" = "test-consumer-group test            0          1               1               0               -               -               -" ]
    [ "${lines[4]}" = "test-consumer-group test            2          1               1               0               -               -               -" ]
}

@test "delete topic" {
    run docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server tansu:9092 --delete --topic test
    [ "${lines[0]}" = "" ]
}
