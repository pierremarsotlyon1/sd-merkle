-include .env

.EXPORT_ALL_VARIABLES:
ETHERSCAN_API_KEY=$(ETHERSCAN_KEY)
FOUNDRY_RPC_URL=$(RPC_URL_MAINNET)
MAKEFLAGS += --no-print-directory

default:
	forge fmt && forge build

# Always keep Forge up to date
install:
	foundryup
	forge install

test:
	@forge test --gas-report

test-f-%:
	@FOUNDRY_MATCH_TEST=$* make test

test-c-%:
	@FOUNDRY_MATCH_CONTRACT=$* make test

test-%:
	@FOUNDRY_TEST=test/$* make test

coverage:
	@forge coverage --report lcov
	@lcov --ignore-errors unused --remove ./lcov.info -o ./lcov.info.pruned "test/*" "script/*"
	@rm ./lcov.info*

coverage-html:
	@make coverage
	@genhtml ./lcov.info.pruned -o report --branch-coverage --output-dir ./coverage
	@rm ./lcov.info*

simulate-%:
	@forge script script/$*.sol -vvvvv

run-%:
	@forge script script/$*.s.sol --broadcast --slow -vvvvv --private-key $(PRIVATE_KEY)

deploy-%:
	@forge script script/$*.sol --broadcast --slow --rpc-url $(RPC_URL_MAINNET) -vvvvv --verify --private-key ${PRIVATE_KEY}