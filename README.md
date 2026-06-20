# ΑΙΘΗΡ · StratoshiVibes Badge

Ένα **soulbound** (μη μεταβιβάσιμο) NFT badge που δείχνει **ζωντανά την τιμή του ETH**, 100% **on-chain**, στο **Base**.

> ΑΙΘΗΡ — Το Πέμπτο Στοιχείο. Σήμα συμμετοχής στην κοινότητα του StratoshiVibes.
> Δωρεάν · Δεν μεταβιβάζεται · Δεν πουλιέται · **Δεν είναι επένδυση.**

---

## Τι είναι

Κάθε μέλος κάνει mint ένα badge (ένα ανά wallet). Το badge:

- **"Θυμάται" την τιμή του ETH** τη στιγμή του mint (joined-at).
- **Δείχνει τη ζωντανή τιμή** μέσω του Chainlink ETH/USD oracle, και το delta % από τότε.
- Έχει **on-chain SVG artwork** — η εικόνα ζει μέσα στο smart contract, όχι σε εξωτερικό server ή IPFS.
- Είναι **soulbound**: οι μεταφορές είναι μπλοκαρισμένες. Δεν υπάρχει αγορά, floor, ή listing — by design.

## Γιατί έτσι

Αυτό το project είναι και ένα **ανοιχτό εκπαιδευτικό παράδειγμα**. Δείχνει στην πράξη:

- Πώς ένα smart contract διαβάζει off-chain δεδομένα μέσω **oracle** (Chainlink Data Feed).
- Πώς φτιάχνεται **dynamic, on-chain** NFT metadata/artwork.
- Γιατί ένα **soulbound** token αποφεύγει εξ ορισμού τα μοτίβα κερδοσκοπίας/scam που διδάσκουμε να αναγνωρίζετε: δεν υπάρχει ρευστότητα να "κλειδωθεί", δεν υπάρχει creator-holdings να ξεπουληθεί, δεν υπάρχει αγορά να χειραγωγηθεί.

Verified contract, χωρίς κρυφό mint, χωρίς admin backdoor στην τιμή. Διαβάστε τον κώδικα — αυτό είναι το νόημα.

## Τεχνικά

| | |
|---|---|
| Network | Base (mainnet) |
| Standard | ERC-721 (soulbound) |
| Oracle | Chainlink ETH/USD Data Feed |
| Artwork | On-chain SVG (base64 data URI) |
| Contract | `0x2B016E704583A9C12b78972e189F09D6375efF14` |

## Δομή

- `contracts/StratoshiVibesAither.sol` — το smart contract.
- `web/index.html` — η claim page (HTML + ethers.js, client-side).

## Mint

Η claim page συνδέει wallet, ελέγχει/αλλάζει δίκτυο σε Base, και καλεί την `mint()`.
Χρειάζεσαι λίγο ETH στο Base για το gas. Δεν υπάρχει κόστος mint πέρα από το gas.

## Disclaimer

Το ΑΙΘΗΡ badge είναι ένα δωρεάν, μη μεταβιβάσιμο, συλλεκτικό/εκπαιδευτικό artifact.
**Δεν αποτελεί επενδυτικό προϊόν, δεν υπόσχεται καμία απόδοση, και δεν αντιπροσωπεύει
κανένα χρηματοοικονομικό δικαίωμα.** Ο κώδικας παρέχεται ως έχει, για εκπαιδευτικούς σκοπούς.

## License

MIT
