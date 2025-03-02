set dotenv-load

docker-compose-up:
    docker compose up --detach

docker-compose-down:
    docker compose down --volumes

docker-compose-ps:
    docker compose ps

docker-compose-logs:
    docker compose logs


minio-local-alias:
    docker compose exec minio /usr/bin/mc alias set local http://localhost:9000 minioadmin minioadmin

minio-tansu-bucket:
    docker compose exec minio /usr/bin/mc mb local/tansu

minio-ready-local:
    docker compose exec minio /usr/bin/mc ready local

up: docker-compose-up minio-ready-local minio-local-alias minio-tansu-bucket

list-topics:
    docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server ${ADVERTISED_LISTENER} --list

test-topic-describe:
    docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server ${ADVERTISED_LISTENER} --describe --topic test

test-topic-create:
    docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server ${ADVERTISED_LISTENER} --config cleanup.policy=compact --partitions=3 --replication-factor=1 --create --topic test

test-topic-delete:
    docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server ${ADVERTISED_LISTENER} --delete --topic test

test-topic-get-offsets-earliest:
    docker compose exec kafka /opt/kafka/bin/kafka-get-offsets.sh --bootstrap-server ${ADVERTISED_LISTENER} --topic test --time earliest

test-topic-get-offsets-latest:
    docker compose exec kafka /opt/kafka/bin/kafka-get-offsets.sh --bootstrap-server ${ADVERTISED_LISTENER} --topic test --time latest

test-topic-produce:
    echo "h1:pqr,h2:jkl,h3:uio	qwerty	poiuy\nh1:def,h2:lmn,h3:xyz	asdfgh	lkj\nh1:stu,h2:fgh,h3:ijk	zxcvbn	mnbvc" | docker compose exec --no-TTY kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server ${ADVERTISED_LISTENER} --topic test --property parse.headers=true --property parse.key=true

test-topic-consume:
    docker compose exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server ${ADVERTISED_LISTENER} --timeout-ms 30000 --consumer-property fetch.max.wait.ms=15000 --group test-consumer-group --topic test --from-beginning --property print.key=true --property print.offset=true --property print.partition=true --property print.headers=true --property print.value=true

test-consumer-group-describe:
    docker compose exec kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server ${ADVERTISED_LISTENER} --group test-consumer-group --describe

consumer-group-list:
    docker compose exec kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server ${ADVERTISED_LISTENER} --list

test-reset-offsets-to-earliest:
    docker compose exec kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server ${ADVERTISED_LISTENER} --group test-consumer-group --topic test:0 --reset-offsets --to-earliest --execute

person-topic-create:
    docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server ${ADVERTISED_LISTENER} --partitions=3 --replication-factor=1 --create --topic person

person-topic-produce-valid:
    echo 'h1:pqr,h2:jkl,h3:uio	"ABC-123"	{"firstName": "John", "lastName": "Doe", "age": 21}' | docker compose exec kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server ${ADVERTISED_LISTENER} --topic person --property parse.headers=true --property parse.key=true

person-topic-produce-invalid:
    echo 'h1:pqr,h2:jkl,h3:uio	"ABC-123"	{"firstName": "John", "lastName": "Doe", "age": -1}' | docker compose exec kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server ${ADVERTISED_LISTENER} --topic person --property parse.headers=true --property parse.key=true

person-topic-consume:
    docker compose exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
        --bootstrap-server ${ADVERTISED_LISTENER} \
        --consumer-property fetch.max.wait.ms=15000 \
        --group person-consumer-group --topic person \
        --from-beginning \
        --property print.timestamp=true \
        --property print.key=true \
        --property print.offset=true \
        --property print.partition=true \
        --property print.headers=true \
        --property print.value=true

bats:
    bats --trace --verbose-run tests

codespace-create:
    gh codespace create \
        --repo $(gh repo view --json nameWithOwner --jq .nameWithOwner) \
        --branch $(git branch --show-current) \
        --machine basicLinux32gb

codespace-delete:
    gh codespace ls \
        --repo $(gh repo view \
            --json nameWithOwner \
            --jq .nameWithOwner) \
        --json name \
        --jq '.[].name' | xargs --no-run-if-empty -n1 gh codespace delete --codespace

codespace-logs:
    gh codespace logs \
        --codespace $(gh codespace ls \
            --repo $(gh repo view \
                --json nameWithOwner \
                --jq .nameWithOwner) \
            --json name \
            --jq '.[].name')

codespace-ls:
    gh codespace list \
        --repo $(gh repo view \
            --json nameWithOwner \
            --jq .nameWithOwner)

codespace-ssh:
    gh codespace ssh \
        --codespace $(gh codespace ls \
            --repo $(gh repo view \
                --json nameWithOwner \
                --jq .nameWithOwner) \
            --json name \
            --jq '.[].name')
