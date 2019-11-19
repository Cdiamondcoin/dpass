export dpass=0x68af071d8b266a8015a6eb22a4c11b3b0ffc6f2d

export issuer=$(seth --to-bytes32 $(seth --from-ascii GIA))
export nr=12328367418
export report=$(seth --to-bytes32 $(seth --from-ascii $nr))
export state=$(seth --to-bytes32 $(seth --from-ascii valid))
export cccc=$(seth --to-bytes32 $(seth --from-ascii "BR,IF,SI1,0001"))
export carat=102
# export algorithm=$(seth --to-bytes32 $(seth --from-ascii 20191118))
export algorithm=3230313931313138

export hash=123,1234,234,234,234,23423,4,23423,42,342,34234
export hash=$(python3 -c "from hashlib import sha256; hash='$hash';  print(f'0x{sha256(hash.encode()).hexdigest()}')")
export to=0x9556E25F9b4D343ee38348b6Db8691d10fD08A61
export custodian=0x9556E25F9b4D343ee38348b6Db8691d10fD08A61

seth send $dpass "setCccc(bytes32,bool)" $cccc true
seth send $dpass "mintDiamondTo(address,address,bytes32,bytes32,bytes32,bytes32,uint24,bytes32,bytes8)" $to $custodian $issuer $report $state $cccc $carat $hash $algorithm
