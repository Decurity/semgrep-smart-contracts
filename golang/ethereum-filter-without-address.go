import (
	"context"
	"math/big"
	"slices"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	ethcommon "github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

func (s *DepositHandler) findTransactionsInBlock(block []uint64, addressesMap map[string]*entities.User) error {
	ctx, cancel := context.WithTimeout(s.ctx, 60*time.Second)
	defer cancel()

	logs, err := s.pipeline.FilterLogs(
		ctx,
		// ruleid: ethereum-filter-without-address
		ethereum.FilterQuery{
			FromBlock: big.NewInt(int64(block[0])),
			ToBlock:   big.NewInt(int64(block[len(block)-1])),
			Topics: [][]common.Hash{{
				common.HexToHash("0x0000"),
			}},
		})
}

func (s *DepositHandler) GetTx(ctx context.Context, user string) (nonce uint32, err error) {
	childCtx, cancel := context.WithTimeout(ctx, ssvScannerTimeout)
	defer cancel()

	packed, err := s.topicArgs.Pack(ethcommon.HexToAddress(user))
	if err != nil {
		return nonce, err
	}

	// ruleid: ethereum-filter-without-address
	query := ethereum.FilterQuery{
		FromBlock: big.NewInt(s.minBlock),
		Topics:    [][]ethcommon.Hash{nil, {ethcommon.BytesToHash(packed)}},
	}

	// ok: ethereum-filter-without-address
	query := ethereum.FilterQuery{
		FromBlock: big.NewInt(s.minBlock),
		Topics:    [][]ethcommon.Hash{nil, {ethcommon.BytesToHash(packed)}},
		Addresses: []common.Address{
			DepositContractAddress,
		},
	}
}
