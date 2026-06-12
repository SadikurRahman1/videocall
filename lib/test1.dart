// import 'package:block_test/bloc/counter_bloc.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => CounterBloc(),
//       child: MaterialApp(
//         title: 'Flutter Demo',
//         debugShowCheckedModeBanner: false,
//         theme: ThemeData(
//           colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         ),
//         home: Home(),
//       ),
//     );
//   }
// }

// class Home extends StatelessWidget {
//   const Home({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
      
//       body: BlocBuilder<CounterBloc, CounterState>(
//         builder: (context, state) {
//           return Center(child: Text('Counter: ${state.count}'));
//         },
//       ),

//       floatingActionButton: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           FloatingActionButton(
//             onPressed: () =>
//                 context.read<CounterBloc>().add(CounterIncremented()),
//             child: Icon(Icons.add),
//           ),
//           SizedBox(height: 10),
//           FloatingActionButton(
//             onPressed: () =>
//                 context.read<CounterBloc>().add(CounterDecremented()),
//             child: Icon(Icons.remove),
//           ),
//         ],
//       ),
//     );
//   }
// }
