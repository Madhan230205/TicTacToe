import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

void main() => runApp(TicTacToeApp());

class TicTacToeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tic-Tac-Toe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StarterScreen(),
    );
  }
}

class StarterScreen extends StatefulWidget {
  @override
  _StarterScreenState createState() => _StarterScreenState();
}

class _StarterScreenState extends State<StarterScreen> {
  bool _playWithTimer = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.purple.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TIC-TAC-TOE',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(2, 2))],
                ),
              ),
              SizedBox(height: 32),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _playWithTimer ? Colors.yellow.shade700 : Colors.white70,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 3))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Play with Timer', style: TextStyle(fontSize: 18, color: Colors.black87)),
                    Switch(
                      value: _playWithTimer,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.grey,
                      onChanged: (val) => setState(() => _playWithTimer = val),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Text('Who starts?', style: TextStyle(fontSize: 20, color: Colors.white70)),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ChoiceButton(symbol: 'X', playWithTimer: _playWithTimer),
                  SizedBox(width: 24),
                  _ChoiceButton(symbol: 'O', playWithTimer: _playWithTimer),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String symbol;
  final bool playWithTimer;
  const _ChoiceButton({required this.symbol, required this.playWithTimer});

  @override
  Widget build(BuildContext context) {
    final color = symbol == 'X' ? Colors.red : Colors.green;
    return Material(
      shape: CircleBorder(),
      elevation: 8,
      color: Colors.white,
      child: InkWell(
        customBorder: CircleBorder(),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GameScreen(
                startingPlayer: symbol,
                playWithTimer: playWithTimer,
              ),
            ),
          );
        },
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          child: Text(
            symbol,
            style: TextStyle(fontSize: 36, color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final String startingPlayer;
  final bool playWithTimer;
  const GameScreen({required this.startingPlayer, required this.playWithTimer});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late List<String> _board;
  late String _currentPlayer;
  bool _gameOver = false;
  List<int> _winningIndices = [];

  late AnimationController _winAnimController;
  late Animation<double> _winAnimation;
  late ConfettiController _confettiController;

  // Timer variables
  Stopwatch _stopwatchX = Stopwatch();
  Stopwatch _stopwatchO = Stopwatch();
  Timer? _timer;
  Duration _elapsedX = Duration.zero;
  Duration _elapsedO = Duration.zero;

  @override
  void initState() {
    super.initState();
    _winAnimController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _winAnimation = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _winAnimController, curve: Curves.easeInOut));
    _confettiController = ConfettiController(duration: Duration(seconds: 2));
    _resetBoard();
  }

  @override
  void dispose() {
    _winAnimController.dispose();
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _resetBoard() {
    _board = List.generate(9, (_) => '');
    _currentPlayer = widget.startingPlayer;
    _gameOver = false;
    _winningIndices.clear();
    _winAnimController.reset();
    _confettiController.stop();
    _stopwatchX
      ..stop()
      ..reset();
    _stopwatchO
      ..stop()
      ..reset();
    _elapsedX = Duration.zero;
    _elapsedO = Duration.zero;
    _timer?.cancel();
    if (widget.playWithTimer) {
      _startTimer();
      _startStopwatchFor(_currentPlayer);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 30), (_) {
      setState(() {
        _elapsedX = _stopwatchX.elapsed;
        _elapsedO = _stopwatchO.elapsed;
      });
    });
  }

  void _startStopwatchFor(String player) {
    if (player == 'X') _stopwatchX.start(); else _stopwatchO.start();
  }

  void _stopStopwatchFor(String player) {
    if (player == 'X') _stopwatchX.stop(); else _stopwatchO.stop();
  }

  void _switchTurns() {
    _stopStopwatchFor(_currentPlayer);
    _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
    if (widget.playWithTimer) _startStopwatchFor(_currentPlayer);
  }

  void _onTap(int index) {
    if (_board[index].isNotEmpty || _gameOver) return;
    setState(() {
      _board[index] = _currentPlayer;
      if (_checkWin()) {
        _gameOver = true;
        _winAnimController.repeat(reverse: true);
        _confettiController.play();
        _timer?.cancel();
        _stopStopwatchFor('X');
        _stopStopwatchFor('O');
        _showResultDialog('$_currentPlayer Wins!');
      } else if (!_board.contains('')) {
        _gameOver = true;
        _timer?.cancel();
        _stopStopwatchFor('X');
        _stopStopwatchFor('O');
        if (widget.playWithTimer) {
          String winner = _elapsedX < _elapsedO ? 'X' : 'O';
          _confettiController.play();
          _showResultDialog('Draw! $winner wins by time');
        } else {
          _showResultDialog('Draw!');
        }
      } else {
        if (widget.playWithTimer) {
          _switchTurns();
        } else {
          // ensure turn switches when timer is off
          _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
        }
      }
    });
  }

  bool _checkWin() {
    const lines = [
      [0,1,2], [3,4,5], [6,7,8],
      [0,3,6], [1,4,7], [2,5,8],
      [0,4,8], [2,4,6],
    ];
    for (var line in lines) {
      final a = line[0], b = line[1], c = line[2];
      if (_board[a].isNotEmpty &&
          _board[a] == _board[b] &&
          _board[a] == _board[c]) {
        _winningIndices = line;
        return true;
      }
    }
    return false;
  }

  void _showResultDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: widget.playWithTimer && title.contains('Draw')
            ? Text('Time: X ${_formatDuration(_elapsedX)} vs O ${_formatDuration(_elapsedO)}')
            : SizedBox.shrink(),
        actions: [
          TextButton(
            child: Text('Restart'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => GameScreen(
                    startingPlayer: widget.startingPlayer,
                    playWithTimer: widget.playWithTimer,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final seconds = twoDigits(d.inSeconds.remainder(60));
    final ms = twoDigits(d.inMilliseconds.remainder(1000) ~/ 10);
    return "$seconds.$ms";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.playWithTimer)
              _TimerCard(label: 'X', time: _formatDuration(_elapsedX), color: Colors.red),
            Text('Player $_currentPlayer', style: TextStyle(color: Colors.black87)),
            if (widget.playWithTimer)
              _TimerCard(label: 'O', time: _formatDuration(_elapsedO), color: Colors.green),
          ],
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.all(24),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    final isWinningCell = _winningIndices.contains(index);
                    return Material(
                      elevation: isWinningCell ? 8 : 4,
                      shadowColor: isWinningCell ? Colors.yellowAccent : Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _onTap(index),
                        child: ScaleTransition(
                          scale: isWinningCell ? _winAnimation : AlwaysStoppedAnimation(1),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: _board[index].isNotEmpty
                                  ? LinearGradient(
                                      colors: _board[index] == 'X'
                                          ? [Colors.red.shade100, Colors.red.shade300]
                                          : [Colors.green.shade100, Colors.green.shade300],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _board[index],
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold,
                                color: _board[index] == 'X' ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  final String label;
  final String time;
  final Color color;
  const _TimerCard({required this.label, required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text(time, style: TextStyle(color: color, fontSize: 16, fontFeatures: [
            FontFeature.tabularFigures(),
          ])),
        ],
      ),
    );
  }
}
