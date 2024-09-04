import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For date formatting
import 'package:share_plus/share_plus.dart';

// Fetch Quote from API
Future<Quote> fetchQuote(DateTime date) async {
  final formattedDate = DateFormat('yyyy-MM-dd').format(date); // Format date as needed
  final response = await http.get(Uri.parse(
      "https://quotes.isha.in/dmq/index.php/Webservice/fetchDailyQuote?date=$formattedDate"));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body)["response"]["data"]?[0];
    return Quote.fromJson(data as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load Quote');
  }
}

// Quote model
class Quote {
  final String image_name;
  final String alt_tag;
  final String lang_text;
  final String show_signature;
  final String announcement;

  const Quote({
    required this.image_name,
    required this.alt_tag,
    required this.lang_text,
    required this.show_signature,
    required this.announcement,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      image_name: json['image_name'],
      alt_tag: json['alt_tag'],
      lang_text: json['lang_text'],
      show_signature: json['show_signature'],
      announcement: json['announcement'],
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quotes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(248, 244, 237, 255)),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

// QuotePage Widget
class QuotePage extends StatefulWidget {
  final DateTime date;
  final Future<Quote> Function(DateTime) fetchQuote;

  const QuotePage({
    required this.date,
    required this.fetchQuote,
    Key? key,
  }) : super(key: key);

  @override
  _QuotePageState createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> with AutomaticKeepAliveClientMixin {
  late Future<Quote> _quoteFuture;
  late Image _imageWidget;
  late SvgPicture _borderBottomWidget;
  late SvgPicture _quoteStartWidget;
  late SvgPicture _signatureWidget;

  @override
  void initState() {
    super.initState();
    _quoteFuture = widget.fetchQuote(widget.date);
    _imageWidget = Image.network('', fit: BoxFit.cover, width: double.infinity); // Placeholder image
    _borderBottomWidget = SvgPicture.network(
      'https://webapp.sadhguru.org/assets/dmq_image_bottom-DB165sh6.svg',
      semanticsLabel: 'borderBottom',
      width: 390,
    );
    _quoteStartWidget = SvgPicture.asset('assets/images/quote.svg', semanticsLabel: 'QuoteStart');
    _signatureWidget = SvgPicture.asset('assets/images/signature.svg', semanticsLabel: 'Signature');
    print('QuotePage initState for ${widget.date}');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    print('QuotePage build for ${widget.date}');
    return FutureBuilder<Quote>(
      future: _quoteFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final quote = snapshot.data!;
          _imageWidget = Image.network(
            quote.image_name,
            fit: BoxFit.cover,
            width: double.infinity,
          ); // Cache image widget
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Column(
                          children: [
                            _imageWidget,
                            Container(
                              transform: Matrix4.translationValues(0.0, -24.0, 0.0),
                              child: _borderBottomWidget,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2),
                      _quoteStartWidget,
                      SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.3,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Column(
                              children: [
                                Text(
                                  quote.lang_text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.height * 0.022,
                                      height: 1.6,
                                      color: Colors.black,
                                      fontFamily: 'FSerStdA-Book'),
                                ),
                                SizedBox(height: 16),
                                _signatureWidget,
                                SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

// MyHomePage Widget
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _currentDate = DateTime.now();
  DateTime _updatedCurrentDate = DateTime.now();
  final Map<DateTime, Future<Quote>> _quotesCache = {};
  late PageController _pageController;
  bool _canScrollRight = true; // To control if right scrolling is enabled

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _loadQuote(_currentDate);
    print('MyHomePage initState');
  }

  Future<void> _loadQuote(DateTime date) async {
    if (!_quotesCache.containsKey(date)) {
      _quotesCache[date] = fetchQuote(date);
      print('Fetching quote for date: $date');
    }
  }

  Future<Quote> _getQuote(DateTime date) async {
    await _loadQuote(date);
    return _quotesCache[date]!;
  }

  DateTime _dateForPage(int pageIndex) {
    return _currentDate.subtract(Duration(days: pageIndex));
  }

  bool get _isCurrentDate {
    return DateTime.now().isAtSameMomentAs(_dateForPage(0));
  }

  void _updateScrollPermissions() {
    setState(() {
      _canScrollRight = DateTime.now().isAfter(_dateForPage(0));
    });
  }

  void _shareQuote() {
    print("Share button pressed");
    Share.share('Sharing this quote', subject: 'Sadhguru Quotes');
  }

  @override
  Widget build(BuildContext context) {
    print('MyHomePage build');
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 248, 244, 237),
      body: PageStorage(
        bucket: PageStorageBucket(),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: null, // Infinite scroll
              reverse: true,
              itemBuilder: (context, index) {
                final date = _dateForPage(index);
                return QuotePage(
                  key: PageStorageKey<DateTime>(date),  // Use PageStorageKey to cache pages
                  date: date,
                  fetchQuote: _getQuote,
                );
              },
              onPageChanged: (int page) {
                setState(() {
                  _updatedCurrentDate = _dateForPage(page);
                  _updateScrollPermissions();
                });
              },
              physics: _isCurrentDate
                  ? NeverScrollableScrollPhysics()
                  : _canScrollRight
                      ? null
                      : NeverScrollableScrollPhysics(),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.08,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  DateFormat('dd MMM yyyy').format(_updatedCurrentDate),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'FSerStdA-Book',
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.06,
              left: MediaQuery.of(context).size.height * 0.03,
              right: MediaQuery.of(context).size.height * 0.03,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _shareQuote,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    backgroundColor: Color.fromARGB(255, 32, 161, 170),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.ios_share_outlined,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Share',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
