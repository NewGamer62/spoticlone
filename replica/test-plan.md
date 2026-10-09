# Test plan: SpotiClone

Build: local-dev  Date: 2026-10-09  Env: local, Flutter 3.38+ (Windows & Android)

| case | flow | type | steps | expected | auto | result |
| --- | --- | --- | --- | --- | --- | --- |
| F01-H1 | Search and play track | happy | open search, enter query, tap track tile | audio starts playing, player bar reflects track metadata | flutter_test | pass |
| F01-E1 | Empty search query | edge | clear search bar | browse categories grid displayed | flutter_test | pass |
| F02-H1 | Queue management | happy | click add to queue on track, open queue | track appears in queue list, can skip to it | flutter_test | pass |
| F02-H2 | Shuffle toggle | happy | click shuffle button in player bar | queue order randomly shuffled, indicator turns green | flutter_test | pass |
| F03-H1 | Favorite / Like track | happy | click heart icon on track | track saved to Liked Songs playlist, state persisted | flutter_test | pass |
| F03-H2 | Create custom playlist | happy | click '+' in library, enter name and desc | new playlist appears in library, tracks can be added | flutter_test | pass |
| F04-H1 | Responsive layout switch | happy | resize window width above/below 768px | smoothly switches between 3-pane desktop and mobile bottom bar | flutter_test | pass |
| F05-H1 | Synchronized lyrics parsing | happy | parse LRC lyrics timestamp format | lyrics lines ordered by timestamp, active line highlighted | flutter_test | pass |
| F05-H2 | Seek by clicking lyrics line | happy | tap lyric text in lyrics viewer | player seeks to exact timestamp of lyric | flutter_test | pass |
