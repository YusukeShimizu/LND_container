# Getting Started
## Run on simnet

```sh
git clone git@github.com:YusukeShimizu/LND_container.git
cd LND_container
docker-compose up -d
docker exec -i -t lnd_btc bash
lncli create
Input wallet password: 
Confirm password:
```
You need to unlock wallet on container.
```
Do you have an existing cipher seed mnemonic you want to use? (Enter y/n): n

Your cipher seed can optionally be encrypted.
Input your passphrase if you wish to encrypt it (or press enter to proceed without a cipher seed passphrase): 

Generating fresh cipher seed...

!!!YOU MUST WRITE DOWN THIS SEED TO BE ABLE TO RESTORE THE WALLET!!!

---------------BEGIN LND CIPHER SEED---------------
 1. abstract   2. high       3. biology   4. slight 
 5. weekend    6. tonight    7. mystery   8. submit 
 9. easily    10. royal     11. wood     12. figure 
13. benefit   14. ordinary  15. ceiling  16. item   
17. lottery   18. next      19. opera    20. clump  
21. faith     22. copper    23. song     24. tuition
---------------END LND CIPHER SEED-----------------

!!!YOU MUST WRITE DOWN THIS SEED TO BE ABLE TO RESTORE THE WALLET!!!

lnd successfully initialized!
```

## Do something

```
docker exec -i -t lnd_btc bash
lncli --network=simnet walletbalance
```

## Reset
```sh
docker-compose down --rmi all
```