import 'package:flutter/material.dart';

class ActionButton extends StatefulWidget {
  final String? title;
  final String subTitle;
  final IconData? icon;
  final bool checked;
  final bool number;
  final Color? fillColor;
  final Color? textColor;
  final double? iconSize;
  final Function()? onPressed;
  final Function()? onLongPress;
  final double? size; // New parameter for size customization

  const ActionButton(
      {Key? key,
      this.title,
      this.subTitle = '',
      this.icon,
      this.onPressed,
      this.onLongPress,
      this.checked = false,
      this.number = false,
      this.fillColor,
      this.textColor,
      this.iconSize,
      this.size = 40.0}) // Default size
      : super(key: key);

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.size ?? 50.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GestureDetector(
            onLongPress: widget.onLongPress,
            onTap: widget.onPressed,
            child: RawMaterialButton(
              onPressed: widget.onPressed,
              splashColor: widget.fillColor ??
                  (widget.checked ? Colors.white : Colors.blue),
              fillColor: widget.fillColor ??
                  (widget.checked ? Colors.blue : Colors.white),
              elevation: 10.0,
              shape: CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(buttonSize * 0.3), // Dynamic padding
                child: widget.number
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                            Text('${widget.title}',
                                style: TextStyle(
                                  fontSize: buttonSize * 0.44, // Dynamic size
                                  color: widget.textColor ?? Colors.grey[500],
                                )),
                            Text(widget.subTitle.toUpperCase(),
                                style: TextStyle(
                                  fontSize: buttonSize * 0.24, // Dynamic size
                                  color: widget.textColor ?? Colors.grey[500],
                                ))
                          ])
                    : Icon(
                        widget.icon,
                        size: buttonSize * 0.8, // Dynamic icon size
                        color: widget.fillColor != null
                            ? Colors.white
                            : (widget.checked ? Colors.white : Colors.blue),
                      ),
              ),
            )),
        widget.number
            ? Container(
                margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0))
            : Container(
                margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                child: (widget.number || widget.title == null)
                    ? null
                    : Text(
                        widget.title!,
                        style: TextStyle(
                          fontSize: buttonSize * 0.3, // Dynamic text size
                          color: widget.textColor ?? Colors.grey[500],
                        ),
                      ),
              )
      ],
    );
  }
}







// import 'package:flutter/material.dart';

// class ActionButton extends StatefulWidget {
//   final String? title;
//   final String subTitle;
//   final IconData? icon;
//   final bool checked;
//   final bool number;
//   final Color? fillColor;
//   final Color? textColor;
//   final Function()? onPressed;
//   final Function()? onLongPress;

//   const ActionButton(
//       {Key? key,
//       this.title,
//       this.subTitle = '',
//       this.icon,
//       this.onPressed,
//       this.onLongPress,
//       this.checked = false,
//       this.number = false,
//       this.fillColor,
//       this.textColor})
//       : super(key: key);

//   @override
//   State<ActionButton> createState() => _ActionButtonState();
// }

// class _ActionButtonState extends State<ActionButton> {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       mainAxisAlignment: MainAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: <Widget>[
//         GestureDetector(
//             onLongPress: widget.onLongPress,
//             onTap: widget.onPressed,
//             child: RawMaterialButton(
//               onPressed: widget.onPressed,
//               splashColor: widget.fillColor ??
//                   (widget.checked ? Colors.white : Colors.blue),
//               fillColor: widget.fillColor ??
//                   (widget.checked ? Colors.blue : Colors.white),
//               elevation: 10.0,
//               shape: CircleBorder(),
//               child: Padding(
//                 padding: const EdgeInsets.all(15.0),
//                 child: widget.number
//                     ? Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: <Widget>[
//                             Text('${widget.title}',
//                                 style: TextStyle(
//                                   fontSize: 22,
//                                   color: widget.textColor ?? Colors.grey[500],
//                                 )),
//                             Text(widget.subTitle.toUpperCase(),
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: widget.textColor ?? Colors.grey[500],
//                                 ))
//                           ])
//                     : Icon(
//                         widget.icon,
//                         size: 35.0,
//                         color: widget.fillColor != null
//                             ? Colors.white
//                             : (widget.checked ? Colors.white : Colors.blue),
//                       ),
//               ),
//             )),
//         widget.number
//             ? Container(
//                 margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0))
//             : Container(
//                 margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
//                 child: (widget.number || widget.title == null)
//                     ? null
//                     : Text(
//                         widget.title!,
//                         style: TextStyle(
//                           fontSize: 15.0,
//                           color: widget.textColor ?? Colors.grey[500],
//                         ),
//                       ),
//               )
//       ],
//     );
//   }
// }
