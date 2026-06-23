// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*//////////////////////////////////////////////////////////////
                  StratoshiVibes ΑΙΘΗΡ Badge
        Soulbound ERC-721 · Base · Chainlink ETH/USD · on-chain SVG
//////////////////////////////////////////////////////////////*/
//
//  ΤΙ ΚΑΝΕΙ:
//  - Κάθε follower κάνει mint ΕΝΑ soulbound (μη μεταβιβάσιμο) badge.
//  - Το badge "θυμάται" την τιμή του ETH τη στιγμή του mint (joined at).
//  - Το tokenURI() φτιάχνει on-chain ΖΩΝΤΑΝΑ ένα SVG που δείχνει:
//      live ETH τιμή (από Chainlink), joined-at, delta %, serial #, ημ/νία mint.
//  - Δεν υπάρχει αγορά/τιμή/listing — by design. Μηδέν κερδοσκοπία.
//
//  ΕΞΑΡΤΗΣΕΙΣ (OpenZeppelin v5.x + Chainlink):
//      npm i @openzeppelin/contracts @chainlink/contracts
//
//  ⚠ ΠΡΙΝ ΤΟ DEPLOY: επαλήθευσε τη διεύθυνση του Base ETH/USD feed στο
//      https://docs.chain.link/data-feeds/price-feeds/addresses  (δίκτυο: Base)
//      και πέρασέ την στον constructor. Δοκίμασε ΠΡΩΤΑ σε Base Sepolia testnet.
//
//  ⚠ Σε L2 (όπως το Base), για production-grade hardening, καλό είναι να
//      ελέγχεις και το "Sequencer Uptime Feed" του Chainlink ώστε να μην
//      διαβάζεις stale τιμή σε περίπτωση sequencer downtime. Για ένα καθαρά
//      διακοσμητικό badge δεν είναι κρίσιμο, αλλά αξίζει να το ξέρεις.

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    function decimals() external view returns (uint8);
}

contract StratoshiVibesAither is ERC721, Ownable {
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    AggregatorV3Interface public immutable ethUsdFeed; // Chainlink ETH/USD (Base)

    uint256 public nextId = 1;        // serial number ξεκινάει από #1
    bool public mintingActive = true; // ο owner μπορεί να το κλείσει

    // Ανά token: η τιμή ETH (raw, 8 decimals) και το timestamp τη στιγμή του mint
    mapping(uint256 => int256) public joinedPrice;
    mapping(uint256 => uint64) public mintedAt;

    string[13] private MONTHS = [
        "", "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
        "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ];

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    // _feed: η ΕΠΑΛΗΘΕΥΜΕΝΗ διεύθυνση του Base ETH/USD feed
    // (γνωστή ως 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70 — ΕΠΙΒΕΒΑΙΩΣΕ ΤΗΝ)
    constructor(address _feed)
        ERC721(unicode"StratoshiVibes ΑΙΘΗΡ", "AITHER")
        Ownable(msg.sender)
    {
        ethUsdFeed = AggregatorV3Interface(_feed);
    }

    /*//////////////////////////////////////////////////////////////
                                MINTING
    //////////////////////////////////////////////////////////////*/

    function mint() external returns (uint256 id) {
        require(mintingActive, "minting closed");
        require(balanceOf(msg.sender) == 0, "one per wallet"); // ένα ανά διεύθυνση

        id = nextId++;
        joinedPrice[id] = _latestPrice(); // κλειδώνει την τρέχουσα τιμή ETH
        mintedAt[id] = uint64(block.timestamp);
        _safeMint(msg.sender, id);
    }

    // Ο holder μπορεί να κάνει burn το δικό του badge αν θέλει να αποχωρήσει.
    function burn(uint256 id) external {
        require(ownerOf(id) == msg.sender, "not owner");
        _burn(id);
    }

    function setMintingActive(bool _active) external onlyOwner {
        mintingActive = _active;
    }

    function totalMinted() external view returns (uint256) {
        return nextId - 1;
    }

    /*//////////////////////////////////////////////////////////////
                       SOULBOUND ENFORCEMENT
    //////////////////////////////////////////////////////////////*/
    //
    // OZ v5: όλες οι μεταφορές περνούν από το _update.
    // Επιτρέπουμε mint (from==0) και burn (to==0). Μπλοκάρουμε κάθε transfer.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override
        returns (address)
    {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert("soulbound: non-transferable");
        }
        return super._update(to, tokenId, auth);
    }

    /*//////////////////////////////////////////////////////////////
                          ORACLE READ
    //////////////////////////////////////////////////////////////*/

    function _latestPrice() internal view returns (int256) {
        (, int256 answer, , , ) = ethUsdFeed.latestRoundData();
        require(answer > 0, "bad oracle price");
        return answer; // 8 decimals (π.χ. 384700000000 = $3,847.00)
    }

    /*//////////////////////////////////////////////////////////////
                            tokenURI
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) public view override returns (string memory) {
        _requireOwned(id);

        string memory svg = _renderSVG(id);
        string memory image = string.concat(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        );

        uint256 joinedUSD = uint256(joinedPrice[id]) / 1e8;
        string memory json = string.concat(
            '{"name":"',
            unicode"ΑΙΘΗΡ Badge #",
            id.toString(),
            '","description":"',
            unicode"StratoshiVibes · ΑΙΘΗΡ — Το Πέμπτο Στοιχείο. Soulbound badge που δείχνει ζωντανά την τιμή του ETH από Chainlink. Non-transferable. Δεν είναι επένδυση.",
            '","image":"',
            image,
            '","attributes":[',
            '{"trait_type":"Joined ETH Price","value":"$',
            _comma(joinedUSD),
            '"},{"trait_type":"Serial","value":',
            id.toString(),
            '},{"trait_type":"Network","value":"Base"}]}'
        );

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        );
    }

    /*//////////////////////////////////////////////////////////////
                         SVG RENDERING
    //////////////////////////////////////////////////////////////*/

    struct Vars {
        string price;   // "$3,847"
        string delta;   // "+83.2% since mint"
        string color;   // χρώμα delta
        string arrow;   // ▲ ή ▼
        string joined;  // "$2,100"
        string serial;  // "#042"
        string date;    // "14 JUN 2026"
    }

    function _renderSVG(uint256 id) internal view returns (string memory) {
        Vars memory v = _computeVars(id);

        // Μέρος Α — κάρτα, monogram, wordmark, ΑΙΘΗΡ έμβλημα
        string memory part1 = string.concat(
            "<svg width='100%' viewBox='0 0 300 388' xmlns='http://www.w3.org/2000/svg'>",
            "<rect x='0' y='0' width='300' height='388' rx='18' fill='#0E2038' stroke='#1B3A5B'/>",
            "<rect x='6' y='6' width='288' height='376' rx='14' fill='none' stroke='#22D3EE' stroke-width='0.75' opacity='0.45'/>",
            "<circle cx='44' cy='48' r='21' fill='#0B1A30' stroke='#22D3EE' stroke-width='1.5'/>",
            "<text x='44' y='56' font-family='sans-serif' font-size='23' font-weight='700' fill='#22D3EE' text-anchor='middle'>S</text>",
            "<text x='78' y='44' font-family='sans-serif' font-size='15' font-weight='500' fill='#EAF6FB'>StratoshiVibes</text>",
            "<text x='78' y='60' font-family='monospace' font-size='8' letter-spacing='2.5' fill='#5A8BA8'>FOUNDING MEMBER</text>",
            "<line x1='24' y1='82' x2='276' y2='82' stroke='#1B3A5B' stroke-width='0.5'/>"
        );

        // Μέρος Β — ΑΙΘΗΡ + υπότιτλος + label τιμής
        string memory part2 = string.concat(
            "<line x1='78' y1='106' x2='112' y2='106' stroke='#22D3EE' stroke-width='0.5' opacity='0.5'/>",
            unicode"<text x='150' y='111' font-family='sans-serif' font-size='16' font-weight='500' letter-spacing='7' fill='#22D3EE' text-anchor='middle'>ΑΙΘΗΡ</text>",
            "<line x1='188' y1='106' x2='222' y2='106' stroke='#22D3EE' stroke-width='0.5' opacity='0.5'/>",
            unicode"<text x='150' y='127' font-family='monospace' font-size='7' letter-spacing='3' fill='#4E7A98' text-anchor='middle'>ΤΟ ΠΕΜΠΤΟ ΣΤΟΙΧΕΙΟ</text>",
            "<text x='150' y='158' font-family='monospace' font-size='9' letter-spacing='3.5' fill='#5A8BA8' text-anchor='middle'>ETHEREUM / USD</text>"
        );

        // Μέρος Γ — η ζωντανή τιμή + delta
        string memory part3 = string.concat(
            "<text x='150' y='202' font-family='monospace' font-size='42' font-weight='700' fill='#EAF6FB' text-anchor='middle'>",
            v.price,
            "</text>",
            "<text x='150' y='225' font-family='monospace' font-size='11' fill='",
            v.color,
            "' text-anchor='middle'>",
            v.arrow, " ", v.delta,
            "</text>"
        );

        // Μέρος Δ — panel με joined / serial / minted
        string memory part4 = string.concat(
            "<rect x='24' y='244' width='252' height='80' rx='11' fill='#13283F'/>",
            "<text x='42' y='268' font-family='monospace' font-size='7.5' letter-spacing='1.5' fill='#5A8BA8'>JOINED AT</text>",
            "<text x='42' y='288' font-family='monospace' font-size='16' fill='#CBE9F5'>",
            v.joined,
            "</text>",
            "<text x='258' y='268' font-family='monospace' font-size='7.5' letter-spacing='1.5' fill='#5A8BA8' text-anchor='end'>SERIAL</text>",
            "<text x='258' y='288' font-family='monospace' font-size='16' fill='#CBE9F5' text-anchor='end'>",
            v.serial,
            "</text>"
        );

        // Μέρος Ε — διαχωριστικό, ημερομηνία, footer
        string memory part5 = string.concat(
            "<line x1='42' y1='300' x2='258' y2='300' stroke='#1B3A5B' stroke-width='0.5'/>",
            "<text x='150' y='316' font-family='monospace' font-size='9' letter-spacing='1.5' fill='#7FA8C2' text-anchor='middle'>MINTED \xc2\xb7 ",
            v.date,
            "</text>",
            "<text x='150' y='350' font-family='monospace' font-size='8' letter-spacing='2' fill='#3E6B86' text-anchor='middle'>SOULBOUND \xc2\xb7 NON-TRANSFERABLE</text>",
            "<text x='150' y='368' font-family='monospace' font-size='8' letter-spacing='3' fill='#2A4A63' text-anchor='middle'>BASE NETWORK</text>",
            "</svg>"
        );

        return string.concat(part1, part2, part3, part4, part5);
    }

    function _computeVars(uint256 id) internal view returns (Vars memory v) {
        int256 joined8 = joinedPrice[id];
        int256 live8 = _latestPrice();

        v.price = string.concat("$", _comma(uint256(live8) / 1e8));
        v.joined = string.concat("$", _comma(uint256(joined8) / 1e8));
        v.serial = string.concat("#", id.toString());
        v.date = _formatDate(mintedAt[id]);

        // delta % (μία δεκαδική θέση)
        uint256 j = uint256(joined8);
        uint256 l = uint256(live8);
        if (j == 0) {
            v.color = "#7FA8C2"; v.arrow = unicode"·"; v.delta = "n/a";
            return v;
        }
        if (l >= j) {
            uint256 pctX10 = (l - j) * 1000 / j;
            v.color = "#4ADE80";          // πράσινο
            v.arrow = unicode"\u25B2";   // ▲
            v.delta = string.concat("+", _pct(pctX10), "% since mint");
        } else {
            uint256 pctX10 = (j - l) * 1000 / j;
            v.color = "#F87171";          // κόκκινο
            v.arrow = unicode"\u25BC";   // ▼
            v.delta = string.concat("-", _pct(pctX10), "% since mint");
        }
    }

    /*//////////////////////////////////////////////////////////////
                           STRING HELPERS
    //////////////////////////////////////////////////////////////*/

    // Μετατρέπει pctX10 (π.χ. 832) σε "83.2"
    function _pct(uint256 pctX10) internal pure returns (string memory) {
        return string.concat((pctX10 / 10).toString(), ".", (pctX10 % 10).toString());
    }

    // Προσθέτει διαχωριστικά χιλιάδων: 3847 -> "3,847"
    function _comma(uint256 value) internal pure returns (string memory) {
        bytes memory s = bytes(value.toString());
        uint256 len = s.length;
        if (len <= 3) return string(s);

        uint256 commas = (len - 1) / 3;
        bytes memory out = new bytes(len + commas);
        uint256 oi = out.length;
        uint256 count = 0;
        for (uint256 i = len; i > 0; i--) {
            out[--oi] = s[i - 1];
            count++;
            if (count % 3 == 0 && i > 1) {
                out[--oi] = ",";
            }
        }
        return string(out);
    }

    // Unix timestamp -> "DD MON YYYY" (αλγόριθμος Howard Hinnant)
    function _formatDate(uint64 ts) internal view returns (string memory) {
        uint256 daysSinceEpoch = uint256(ts) / 86400;
        uint256 z = daysSinceEpoch + 719468;
        uint256 era = z / 146097;
        uint256 doe = z - era * 146097;
        uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        uint256 y = yoe + era * 400;
        uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
        uint256 mp = (5 * doy + 2) / 153;
        uint256 d = doy - (153 * mp + 2) / 5 + 1;
        uint256 m = mp < 10 ? mp + 3 : mp - 9;
        if (m <= 2) y += 1;

        string memory dd = d < 10
            ? string.concat("0", d.toString())
            : d.toString();

        return string.concat(dd, " ", MONTHS[m], " ", y.toString());
    }
}
