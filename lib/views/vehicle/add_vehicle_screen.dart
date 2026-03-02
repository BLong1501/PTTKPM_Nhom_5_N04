import 'dart:io';

// import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';

class AddVehicleScreen extends StatefulWidget {
  final bool isStorePost;
  final VehicleModel? vehicleToEdit;
  const AddVehicleScreen({
    super.key,
    this.isStorePost = false,
    this.vehicleToEdit,
  });

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho các ô nhập liệu văn bản
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  // --- THÊM MỚI ---
  final TextEditingController _capacityController =
      TextEditingController(); // Dung tích
  final TextEditingController _weightController =
      TextEditingController(); // Trọng lượng

  String? _selectedCondition; // Lưu tình trạng xe
  String? _selectedOrigin; // Lưu xuất xứA

  // List dữ liệu cứng (Hoặc lấy từ Provider nếu muốn)
  final List<String> _conditions = ["Xe mới", "Đã sử dụng"];
  final List<String> _origins = ["Lắp ráp trong nước", "Nhập khẩu"];
  // Biến lưu giá trị được chọn từ Dropdown
  // Lưu ý: Để null ban đầu để bắt buộc người dùng phải chọn
  String? _selectedCategory;
  String? _selectedBrand;
  String? _selectedFuel;
  String? _selectedLocation;
  String? _selectedColor; // Thêm biến này

  // 3. Biến quản lý danh sách ảnh đã chọn
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  List<String> _existingImages = [];
  @override
  void initState() {
    super.initState();
    // 1. GỌI HÀM TẢI DỮ LIỆU TỪ FIREBASE KHI MỞ MÀN HÌNH
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehicleProvider>(context, listen: false).fetchAppConfig();
    });
    if (widget.vehicleToEdit != null) {
      final v = widget.vehicleToEdit!;

      // 1. Điền text
      _titleController.text = v.title;
      _priceController.text = v.price.toStringAsFixed(0); // Bỏ số lẻ .0
      _yearController.text = v.year.toString();
      _mileageController.text = v.mileage.toString();
      _phoneController.text = v.contactPhone;
      _descController.text = v.description;
      _capacityController.text = v.capacity;
      _weightController.text = v.weight.toString();

      // 2. Điền dropdown (Gán trực tiếp)
      _selectedCategory = v.category;
      _selectedBrand = v.brand;
      _selectedFuel = v.fuelType;
      _selectedLocation = v.location;
      _selectedColor = v.color;
      _selectedCondition = v.condition;
      _selectedOrigin = v.origin;

      // 3. Lưu ảnh cũ
      _existingImages = List.from(v.images);
    }
  }

  // 4. Hàm chọn ảnh từ thư viện
  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker
        .pickMultiImage(); // Chọn nhiều ảnh
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((e) => File(e.path)).toList());
      });
    }
  }
  
  // Hàm xóa ảnh đã chọn (nếu user đổi ý)
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Không cần khai báo final vehicleProvider ở đây nữa vì đã dùng Consumer bên dưới
    return Scaffold(
      appBar: AppBar(
  title: Text(
    widget.vehicleToEdit != null ? "Cập nhật tin" : "Đăng tin bán xe",
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
  flexibleSpace: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF5D3FD3), Color(0xFFC51162)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),
),
      body: Consumer<VehicleProvider>(
        // 2. DÙNG CONSUMER ĐỂ LẤY DỮ LIỆU
        builder: (context, provider, child) {
          // Nếu đang tải dữ liệu thì hiện vòng quay
          if (provider.categories.isEmpty && provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Thông tin cơ bản",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "Tiêu đề bài đăng (VD: Honda Vision 2023)",
                  ),
                  validator: (val) =>
                      val!.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                ),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: "Giá bán (VNĐ)",
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) => val!.isEmpty ? 'Nhập giá' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      // 3. DROPDOWN LOẠI XE (Lấy từ provider.categories)
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        hint: const Text("Loại xe"),
                        items: provider.categories
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val;
                            _selectedBrand =
                                null; // ⚠️ QUAN TRỌNG: Reset hãng xe khi đổi loại xe
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Text(
                  "Thông số kỹ thuật",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),

                // 4. DROPDOWN HÃNG XE (Thay cho TextField cũ)
                Consumer<VehicleProvider>(
                  // Dùng Consumer để chắc chắn lấy dữ liệu mới nhất
                  builder: (context, provider, _) {
                    // Gọi hàm lọc mà ta vừa viết trong Provider
                    final filteredBrands = provider.getBrandsByCategory(
                      _selectedCategory,
                    );

                    return DropdownButtonFormField<String>(
                      value: _selectedBrand,
                      hint: const Text("Chọn Hãng xe"),
                      // Nếu chưa chọn Loại xe thì disable dropdown hãng
                      items: _selectedCategory == null
                          ? []
                          : filteredBrands
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                      onChanged: (val) => setState(() => _selectedBrand = val),
                      // Thêm dòng này để nếu list rỗng thì báo người dùng
                      decoration: InputDecoration(
                        labelText: "Hãng xe",
                        helperText: _selectedCategory == null
                            ? "Vui lòng chọn Loại xe trước"
                            : null,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCondition,
                        hint: const Text("Tình trạng"),
                        items: _conditions
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCondition = val;
                            if (val == "Xe mới")
                              _mileageController.text =
                                  "0"; // Xe mới thì Odo = 0
                          });
                        },
                        validator: (val) =>
                            val == null ? 'Chọn tình trạng' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedOrigin,
                        hint: const Text("Xuất xứ"),
                        items: _origins
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedOrigin = val),
                        validator: (val) => val == null ? 'Chọn xuất xứ' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. SỐ KM & TRỌNG LƯỢNG
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _mileageController,
                        enabled:
                            _selectedCondition !=
                            "Xe mới", // Khóa nếu là xe mới
                        decoration: const InputDecoration(
                          labelText: "Số Km đã đi",
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) => val!.isEmpty ? 'Nhập số Km' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: "Trọng lượng (kg)",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3. DUNG TÍCH
                TextFormField(
                  controller: _capacityController,
                  decoration: const InputDecoration(
                    labelText: "Dung tích động cơ (VD: 150cc, 2.0L)",
                  ),
                ),
                const SizedBox(height: 20),
                // 👇 THÊM DROPDOWN MÀU SẮC TẠI ĐÂY
                DropdownButtonFormField<String>(
                  value: _selectedColor,
                  hint: const Text("Màu sắc"),
                  items: provider
                      .colors // Lấy danh sách màu từ Provider bạn vừa sửa
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedColor = val),
                  validator: (val) => val == null ? 'Chọn màu xe' : null,
                  decoration: const InputDecoration(
                    labelText: "Màu ngoại thất",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: "Năm sản xuất",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      // 5. DROPDOWN NHIÊN LIỆU (Lấy từ provider.fuelTypes)
                      child: DropdownButtonFormField<String>(
                        value: _selectedFuel,
                        hint: const Text("Nhiên liệu"),
                        items: provider.fuelTypes
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _selectedFuel = val),
                        decoration: const InputDecoration(
                          labelText: "Nhiên liệu",
                        ),
                      ),
                    ),
                  ],
                ),

                // 6. DROPDOWN ĐỊA ĐIỂM (Thay cho TextField cũ)
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  hint: const Text("Chọn khu vực bán"),
                  items: provider.locations
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedLocation = val),
                  validator: (val) => val == null ? 'Chọn khu vực' : null,
                  decoration: const InputDecoration(
                    labelText: "Khu vực / Thành phố",
                  ),
                ),

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "Số điện thoại liên hệ",
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val!.isEmpty ? 'Nhập SĐT' : null,
                ),

                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: "Mô tả chi tiết",
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 20),
                // --- THÊM GIAO DIỆN CHỌN ẢNH TẠI ĐÂY ---
                const Text(
                  "Hình ảnh xe (Tối đa 10 ảnh)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),

               SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // 1. NÚT THÊM ẢNH (Luôn nằm đầu tiên)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.grey),
                              Text(
                                "Thêm ảnh",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. HIỂN THỊ ẢNH CŨ (URL TỪ FIREBASE) - Nếu đang sửa
                      // Dùng ... (spread operator) để trải danh sách ra
                      ..._existingImages.asMap().entries.map((entry) {
                        int index = entry.key;
                        String imageUrl = entry.value;
                        
                        return Stack(
                          children: [
                            Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  imageUrl, // 👇 Dùng Image.network cho ảnh cũ
                                  fit: BoxFit.cover,
                                  loadingBuilder: (ctx, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                  },
                                  errorBuilder: (ctx, error, stack) => const Icon(Icons.error),
                                ),
                              ),
                            ),
                            // Nút Xóa ảnh cũ
                            Positioned(
                              right: 5,
                              top: 5,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _existingImages.removeAt(index); // Xóa khỏi list ảnh cũ
                                  });
                                },
                                child: const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close, size: 15, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),

                      // 3. HIỂN THỊ ẢNH MỚI (FILE TỪ ĐIỆN THOẠI)
                      ..._selectedImages.asMap().entries.map((entry) {
                        int index = entry.key;
                        File imageFile = entry.value;

                        return Stack(
                          children: [
                            Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: FileImage(imageFile), // 👇 Dùng FileImage cho ảnh mới
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Nút Xóa ảnh mới
                            Positioned(
                              right: 5,
                              top: 5,
                              child: GestureDetector(
                                onTap: () => _removeImage(index), // Xóa khỏi list ảnh mới
                                child: const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close, size: 15, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const Divider(height: 30),

                const SizedBox(height: 30),
                provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 170, 47, 123),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () => _submitData(provider),
                        child: const Text(
                          "ĐĂNG TIN NGAY",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Nhớ import ở đầu file:
  // import '../../providers/auth_provider.dart';

  void _submitData(VehicleProvider provider) async {
    if (_formKey.currentState!.validate()) {
      
      // 1. 👇 SỬA VALIDATE ẢNH: Phải có ít nhất 1 ảnh (Cũ HOẶC Mới đều được)
      if (_selectedImages.isEmpty && _existingImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn ít nhất 1 ảnh xe!")),
        );
        return;
      }

      // 2. Lấy thông tin User
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi: Không tìm thấy thông tin người dùng!")),
        );
        return; 
      }

      // --- LOGIC TÊN SHOP (Giữ nguyên) ---
      String? finalStoreName;
      if (widget.isStorePost) {
        if (currentUser.storeName != null && currentUser.storeName!.isNotEmpty) {
          finalStoreName = currentUser.storeName;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lỗi: Bạn chưa thiết lập tên cửa hàng!")),
          );
          return;
        }
      } else {
        finalStoreName = null; 
      }
      // ------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đang xử lý dữ liệu...")),
      );

      // 3. 👇 SỬA LOGIC UPLOAD ẢNH: GỘP ẢNH CŨ VÀ MỚI
      List<String> finalImageUrls = [..._existingImages]; // Bắt đầu bằng list ảnh cũ

      // Nếu có chọn ảnh mới thì upload và nối vào
      if (_selectedImages.isNotEmpty) {
        List<String> newImageUrls = await provider.uploadImages(_selectedImages);
        if (newImageUrls.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lỗi tải ảnh mới, vui lòng thử lại!")),
          );
          return;
        }
        finalImageUrls.addAll(newImageUrls);
      }

      // 4. 👇 SỬA TẠO MODEL: Dùng ID cũ và Ngày tạo cũ nếu đang sửa
      final newVehicle = VehicleModel(
        // Nếu đang sửa thì dùng ID cũ, nếu mới thì để rỗng
        id: widget.vehicleToEdit?.id ?? '', 
        
        ownerId: currentUser.uid,
        storeName: finalStoreName, 

        title: _titleController.text,
        description: _descController.text,
        price: double.parse(_priceController.text),
        brand: _selectedBrand!,
        category: _selectedCategory!,
        year: int.parse(_yearController.text),
        mileage: int.tryParse(_mileageController.text) ?? 0,
        fuelType: _selectedFuel ?? 'Xăng',
        location: _selectedLocation!,
        color: _selectedColor!,
        
        images: finalImageUrls, // Dùng list ảnh đã gộp
        
        contactPhone: _phoneController.text,
        // Nếu sửa thì giữ ngày tạo cũ, nếu mới thì lấy ngày giờ hiện tại
        createdAt: widget.vehicleToEdit?.createdAt ?? DateTime.now(),
        
        // Khi sửa xong, có thể giữ nguyên status cũ hoặc reset về 'pending' để duyệt lại
        // Ở đây mình để 'pending' để an toàn (sửa giá/ảnh phải duyệt lại)
        status: 'pending', 
        
        condition: _selectedCondition!,
        origin: _selectedOrigin!,
        capacity: _capacityController.text,
        weight: int.tryParse(_weightController.text) ?? 0,
      );

      // 5. 👇 SỬA GỬI DỮ LIỆU: Phân biệt Update và Create
      bool success;
      
      if (widget.vehicleToEdit != null) {
        //  - Gọi hàm Update
        success = await provider.updateVehicle(newVehicle);
      } else {
        // 

// [Image of Data Creation Flow]
//  - Gọi hàm Create
        success = await provider.uploadVehicle(newVehicle);
      }
      
      if (success && mounted) {
        Navigator.pop(context);
        
        String actionText = widget.vehicleToEdit != null ? "Cập nhật" : "Đăng tin";
        String message = widget.isStorePost 
            ? "Đã $actionText dưới tên Cửa hàng!"
            : "Đã gửi yêu cầu $actionText!";
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    }
  }
}
