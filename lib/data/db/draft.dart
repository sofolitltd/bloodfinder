// // District Autocomplete
// CustomAutocomplete(
// label: 'Select District',
// items: AppData.districts.map((e) => e.name).toList(),
// onSelected: (value) {
// setState(() {
// _selectedDistrict = value;
// _subDistrictList = AppData.districts
//     .firstWhere((d) => d.name == value)
//     .subDistricts;
// _selectedSubDistrict = '';
// });
// },
// onClear: () {
// setState(() {
// _selectedDistrict = '';
// _selectedSubDistrict = '';
// _subDistrictList = [];
// });
// },
// ),
// const SizedBox(height: 12),
//
// // Subdistrict Autocomplete
// CustomAutocomplete(
// label: _selectedDistrict.isEmpty
// ? 'Select District first'
//     : 'Select Subdistrict',
// enabled: _selectedDistrict.isNotEmpty,
// items: _subDistrictList,
// onSelected: (value) {
// setState(() => _selectedSubDistrict = value);
// },
// ),
