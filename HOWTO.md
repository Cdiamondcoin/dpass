## How to create keystore file from private key

### Prerequisities

`pip install eth-account`

### Code

```python
import json
from eth_account import Account

enc = Account.encrypt('YOUR PRIVATE KEY', 'YOUR PASSWORD')

with open('/Users/vgaicuks/code/dpass/rinkeby.keystore', 'w') as f:
    f.write(json.dumps(enc))

```


## Verify contract code

### Flatten contract to upload code etherscan

```bash
hevm flatten --source-file src/Dpass.sol --json-file out/Dpass.sol.json > Dpass-flatt.sol
```


### Get compiller version (set on upload time)

```bash
solc --version
```
