# sc64-n64-boxart-pack

A complete N64 boxart pack for the [SummerCart64](https://summercart64.dev/) flashcart, covering US, JP, and EU titles. Structured to work out of the box with the [N64 Flashcart Menu](https://menu.summercart64.dev/).

Maintained by [Glazed Watermelon](https://www.youtube.com/@glazed_watermelon) — gaming tech reviews and retro gaming tools.

---

## What's included

- Front cover art for US (NTSC), Japanese, and European (PAL) N64 titles
- Images resized to the correct SC64 menu dimensions (158x112 for US/EU, 112x158 for JP)
- Structured as `menu/metadata/X/X/X/X/boxart_front.png` using the 4-character game code from each ROM's header
- Sourced from the [official n64-flashcart-menu-metadata repo](https://github.com/n64-tools/n64-flashcart-menu-metadata) and [GameTDB](https://www.gametdb.com/) as a fallback

---

## Installation

### Option 1: Download the zip (easiest)

1. Go to the [Releases](../../releases) page and download the latest `sc64_boxart_pack.zip`
2. Unzip it into the **root** of your SC64 SD card:

**Mac / Linux:**
```bash
unzip sc64_boxart_pack.zip -d /Volumes/SUMCART64
```

**Windows:**
Right-click the zip → Extract All → navigate to your SD card root

3. Eject and insert your SD card. The SC64 menu will pick up the art automatically.

### Option 2: Clone and build from source

Requires `git`, `python3`, `curl`, and `Pillow`:

```bash
pip3 install Pillow
bash build_boxart_pack.sh
unzip sc64_boxart_pack.zip -d /Volumes/SUMCART64
```

This fetches the latest art from all sources and builds a fresh zip.

---

## File structure

After unzipping, your SD card will contain:

```
menu/
  metadata/
    N/
      G/
        E/
          E/
            boxart_front.png   ← GoldenEye 007 (USA)
      Z/
        L/
          E/
            boxart_front.png   ← Zelda: Ocarina of Time (USA)
    C/
      Z/
        L/
          E/
            boxart_front.png   ← Zelda: OoT (special edition)
    ...
```

The folder path is derived from the 4-character game code stored in each ROM's header (e.g. GoldenEye = `NGEE`).

---

## Compatibility

| SC64 Menu Version | Compatible |
|---|---|
| v2.0.0 and later | Yes |
| v1.x | No (used a different 2-letter format) |

If you are on an older menu version, update your `sc64menu.n64` first. The latest menu release is at [github.com/Polprzewodnikowy/N64FlashcartMenu](https://github.com/Polprzewodnikowy/N64FlashcartMenu/releases).

---

## Coverage

| Region | Titles covered |
|---|---|
| US (NTSC) | ~350+ |
| Japan | ~70+ |
| Europe (PAL) | ~300+ |

Some obscure protos, kiosk demos, and fan translations may not have art available from any source. If you have art for a missing title, contributions are welcome.

---

## Contributing

Found a game with missing or incorrect art? Open an issue or pull request.

For a new cover submission:
1. Image must be PNG format
2. US/EU: 158x112 pixels. JP: 112x158 pixels
3. Place at the correct path using the 4-character game code (visible in the SC64 menu or readable from the ROM header)
4. Source must be your own scan or a freely licensed image

---

## Building the pack yourself

The `build_boxart_pack.sh` script automates the full build:

```bash
bash build_boxart_pack.sh
```

It will:
1. Clone/update the official metadata repo
2. Copy all available official art
3. Fetch missing titles from GameTDB
4. Resize all images to the correct SC64 dimensions
5. Package everything into `sc64_boxart_pack.zip`

---

## Credits

- [n64-flashcart-menu-metadata](https://github.com/n64-tools/n64-flashcart-menu-metadata) — primary art source
- [GameTDB](https://www.gametdb.com/) — fallback cover art database
- [N64 Flashcart Menu](https://github.com/Polprzewodnikowy/N64FlashcartMenu) — the SC64 menu project
- [Glazed Watermelon](https://www.youtube.com/@glazed_watermelon) — pack compilation and tooling

---

## License

The build scripts (`build_boxart_pack.sh`, `get_boxart.sh`) are released under the [MIT License](LICENSE-MIT).

The compiled artwork pack is released under [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)](https://creativecommons.org/licenses/by-nc-sa/4.0/).

This means you are free to share and adapt the pack as long as you give appropriate credit, do not use it for commercial purposes, and distribute any derivatives under the same license.

Original artwork copyright belongs to their respective publishers. This pack is intended for use with legitimately owned game cartridges.

---

## Stay connected

Subscribe to [Glazed Watermelon on YouTube](https://www.youtube.com/@glazed_watermelon) for SC64 setup guides, N64 flashcart reviews, and retro gaming tech content.
