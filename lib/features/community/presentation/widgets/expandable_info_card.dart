import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class ExpandableInfoCard extends StatefulWidget {
  const ExpandableInfoCard({super.key});

  @override
  State<ExpandableInfoCard> createState() => _ExpandableInfoCardState();
}

class _ExpandableInfoCardState extends State<ExpandableInfoCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(top: 8.h),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20.w,
                        color: Colors.red,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Read Before create community!',
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Create community for your school, college, university, or family. Tap to view/hide community guidelines.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            AnimatedCrossFade(
                              alignment: Alignment.centerLeft,
                              firstChild: const SizedBox.shrink(),
                              secondChild: Padding(
                                padding: EdgeInsets.only(top: 12.h),
                                child: Text(
                                  "- Add at least 10 members within 1 month.\n"
                                  "- Communities not meeting the guidelines may be removed.\n"
                                  "- You'll be notified before any removal.",
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    height: 1.4,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              crossFadeState: _expanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 8.w,
                  bottom: 4.h,
                  child: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.red,
                    size: 28.w,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
