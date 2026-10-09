import '../domain/models/track.dart';
import '../domain/models/playlist.dart';

class MusicCatalog {
  static final List<Track> allTracks = [
    const Track(
      id: 'trk-1',
      title: 'Midnight City Lights',
      artist: 'Aether Wave',
      album: 'Neon Dreams',
      duration: Duration(minutes: 3, seconds: 45),
      audioUrl: 'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3?filename=lofi-study-112191.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
      lyricsLrc: '''[00:00.00] (Instrumental Intro)
[00:15.00] Walking down the avenue under neon lights
[00:25.00] Echoes of the radio through the endless nights
[00:38.00] Feel the rhythm taking over my mind
[00:50.00] Leaving all the daily shadows behind
[01:05.00] Midnight city, calling out our names
[01:20.00] Sparkling reflections in the window frames
[01:40.00] (Synth Solo)
[02:10.00] Just you and I beneath the starry sky
[02:30.00] Midnight city never says goodbye''',
    ),
    const Track(
      id: 'trk-2',
      title: 'Coffee in Paris',
      artist: 'Chilled Velvet',
      album: 'Sunday Morning Café',
      duration: Duration(minutes: 2, seconds: 50),
      audioUrl: 'https://cdn.pixabay.com/download/audio/2022/01/18/audio_d0a13f69d2.mp3?filename=chill-abstract-intention-12099.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&auto=format&fit=crop&q=80',
      lyricsLrc: '''[00:00.00] (Acoustic Guitar Melodies)
[00:12.00] Warm cup of coffee on a rainy day
[00:24.00] Watching cobblestones as footsteps fade away
[00:40.00] Time slows down in the morning breeze
[00:55.00] Sweet melody swaying in the trees''',
    ),
    const Track(
      id: 'trk-3',
      title: 'Cyberpunk Horizon',
      artist: 'Glitch Runner',
      album: 'Synthetic Evolution',
      duration: Duration(minutes: 4, seconds: 12),
      audioUrl: 'https://cdn.pixabay.com/download/audio/2022/03/15/audio_c8c8a73467.mp3?filename=electronic-future-beats-117997.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80',
      lyricsLrc: '''[00:00.00] (Analog Synthesizer Arpeggios)
[00:20.00] Holographic skyline rising high
[00:35.00] Electric currents racing in the sky
[00:52.00] Binary pulses deep inside the core
[01:10.00] We will fly beyond the digital shore''',
    ),
    const Track(
      id: 'trk-4',
      title: 'Solar Echoes',
      artist: 'Luna Solaris',
      album: 'Cosmic Journey',
      duration: Duration(minutes: 3, seconds: 20),
      audioUrl: 'https://cdn.pixabay.com/download/audio/2022/10/14/audio_9939f792cb.mp3?filename=tuesday-glitch-122413.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&auto=format&fit=crop&q=80',
      lyricsLrc: '''[00:00.00] (Deep Space Ambience)
[00:15.00] Gravity pulls us to the distant sun
[00:30.00] A stellar voyage has just begun
[00:45.00] Floating weightless across the Milky Way
[01:00.00] Waiting for the dawn of another day''',
    ),
    const Track(
      id: 'trk-5',
      title: 'Sunset Boulevard Groove',
      artist: 'The Funk Collective',
      album: 'Retro Funk Revival',
      duration: Duration(minutes: 3, seconds: 15),
      audioUrl: 'https://cdn.pixabay.com/download/audio/2021/08/09/audio_88424c1045.mp3?filename=groove-ambient-11041.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&auto=format&fit=crop&q=80',
      lyricsLrc: '''[00:00.00] (Slap Bass Groove)
[00:10.00] Get on your feet and dance all night
[00:22.00] The groove is hot, the beat is tight
[00:36.00] Golden hour shining on the coast
[00:50.00] This is the vibe that we love the most''',
    ),
    const Track(
      id: 'trk-6',
      title: 'Deep Focus Coding',
      artist: 'Binary Mind',
      album: 'Algorithms in Flow',
      duration: Duration(minutes: 4, seconds: 05),
      audioUrl: 'https://cdn.pixabay.com/download/audio/2022/02/07/audio_d0c6ff1bab.mp3?filename=ambient-piano-amp-strings-10711.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=600&auto=format&fit=crop&q=80',
      lyricsLrc: '''[00:00.00] (Subtle binaural ambient beats)
[01:00.00] Pure state of flow
[02:00.00] Focus uninterrupted
[03:00.00] Clean architecture in mind''',
    ),
  ];

  static List<Playlist> get initialPlaylists => [
    Playlist(
      id: 'pl-top-hits',
      title: "Today's Top Hits",
      description: "The hottest tracks right now across the globe.",
      coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&auto=format&fit=crop&q=80',
      tracks: [allTracks[0], allTracks[2], allTracks[4]],
      isCustom: false,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Playlist(
      id: 'pl-lofi',
      title: 'Lo-Fi Chill & Study',
      description: 'Mellow beats, cozy study vibes, relax and unwind.',
      coverUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&auto=format&fit=crop&q=80',
      tracks: [allTracks[1], allTracks[5]],
      isCustom: false,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Playlist(
      id: 'pl-synthwave',
      title: 'Synthwave & Retrowave',
      description: 'Outrun the grid with 80s analog nostalgia.',
      coverUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80',
      tracks: [allTracks[0], allTracks[2]],
      isCustom: false,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Playlist(
      id: 'pl-coding',
      title: 'Deep Focus & Flow',
      description: 'Instrumental ambient soundscapes for productive coding sessions.',
      coverUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=600&auto=format&fit=crop&q=80',
      tracks: [allTracks[3], allTracks[5]],
      isCustom: false,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static final List<Map<String, dynamic>> genreCategories = [
    {'title': 'Pop', 'color': 0xFFE13300},
    {'title': 'Hip-Hop', 'color': 0xFF1E3264},
    {'title': 'Rock', 'color': 0xFFE91429},
    {'title': 'Indie', 'color': 0xFF8D67AB},
    {'title': 'Electronic', 'color': 0xFFE8115B},
    {'title': 'Lo-Fi & Chill', 'color': 0xFF006450},
    {'title': 'Jazz', 'color': 0xFF503750},
    {'title': 'Classical', 'color': 0xFF477D95},
    {'title': 'Gaming', 'color': 0xFFE61E32},
    {'title': 'Focus & Coding', 'color': 0xFF1E3264},
  ];
}
