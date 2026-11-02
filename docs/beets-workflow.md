# Beets workflow (in-place mode)

Config: `config/beets/config.yaml` (ported from Nyx's
`.config/beets/config.yaml`). In-place mode: tags are written to your
files, but beets never copies, moves, or reorganizes them. You own the
folders/albums/playlists.

## Golden rules

- Never run `beet move` — it's the one command that applies `paths:`
  (`Albums/…`) and reorganizes your library.
- Always import with `-C -M` (no copy, no move), even though the config
  already sets both to `no`. Habit beats config.
- Bulk imports skip autotag (`import.autotag: no`). Opt in per album
  when you want MusicBrainz.

## First-time import

```sh
beet import -C -M -A ~/Music
```

Builds the DB at `~/Music/.beets/library.db` without touching files.
`incremental: yes` means re-runs skip already-imported files.
Progress/errors go to `~/Music/.beets/beet.log`.

## Tag one album via MusicBrainz

```sh
beet import --autotag /path/to/one-album
# or, for entries already in the DB:
beet mbsync <query>
```

Review the match, confirm, and `write: yes` embeds the tags into your
files in place.

## Manual tag fixes (no MusicBrainz)

```sh
beet mod artist:X album:Y <query>  # set fields in DB + files
beet edit <query>                  # open in $EDITOR (track/title/artist/album/year)
beet write <query>                 # flush DB changes to file tags
beet info <query>                  # inspect stored metadata
```

## Artwork (automatic)

- `fetchart.auto: yes` saves `cover.jpg` next to the music on import.
- `embedart.auto: yes` embeds it into the files.
- Refetch a bad cover: `beet fetchart -f <query>`

## You organize, beets follows

Move/rename folders and playlists freely (kew/feishin read the same
files), then resync:

```sh
beet update      # pick up your moves/renames into the DB
beet missing     # DB entries whose files are gone
beet dup         # duplicate albums (tiebreak: higher bitrate wins)
beet unimported  # files never imported (ignores unsorted/)
```

## Querying (feeds manual playlists)

```sh
beet ls <query>    # matches, displayed by path
beet ls -p <query> # paths only — pipe into .m3u files you manage yourself
```

## On-demand conversion (never automatic)

```sh
beet convert -d <outdir> <query>  # 320k MP3; lossy sources never re-converted
```

Output lands under `~/Music/.beets/converted` by default.
