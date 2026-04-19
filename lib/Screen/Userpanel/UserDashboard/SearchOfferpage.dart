

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:developer';

import '../../../Controllers/FavoritesController.dart';
import '../../../Controllers/OfferSearchController.dart';
import '../OfferDetailsPage.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final OfferSearchController searchController = Get.put(OfferSearchController());
  final FavoritesController favoritesController = Get.find<FavoritesController>();
  
  String? selectedBrand;
  String? selectedCategory;
  String selectedPriceOrder = 'none'; // none | low_high | high_low

  @override
  void initState() {
    super.initState();
    // Focus on search field when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    // Clear search results when leaving the page
    searchController.clearSearch();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      // Always use search API with product name first
      searchController.searchOffers(
        query,
        brand: selectedBrand,
        category: selectedCategory,
      );
    } else if (selectedBrand != null && selectedBrand!.isNotEmpty) {
      // If only brand is selected without query, use filter API
      searchController.filterOffersByBrand(selectedBrand!);
    }
  }

  // Return a sorted copy of current results based on selectedPriceOrder
  List<Map<String, dynamic>> _getSortedResults() {
    final List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(searchController.searchResults);
    if (selectedPriceOrder == 'low_high') {
      results.sort((a, b) {
        final double pa = double.tryParse(a['offer_price']?.toString() ?? '') ?? double.infinity;
        final double pb = double.tryParse(b['offer_price']?.toString() ?? '') ?? double.infinity;
        return pa.compareTo(pb);
      });
    } else if (selectedPriceOrder == 'high_low') {
      results.sort((a, b) {
        final double pa = double.tryParse(a['offer_price']?.toString() ?? '') ?? double.negativeInfinity;
        final double pb = double.tryParse(b['offer_price']?.toString() ?? '') ?? double.negativeInfinity;
        return pb.compareTo(pa);
      });
    }
    return results;
  }

  void _navigateToOfferDetails(String offerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfferDetailsPage(offerId: offerId),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.tune, color: Colors.red[600], size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Filter Results',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Brand Filter
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.branding_watermark, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Brand',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() => DropdownButtonFormField<String>(
                      value: selectedBrand,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red[400]!),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Select Brand',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Brands'),
                        ),
                        ...searchController.availableBrands.map((brand) => 
                          DropdownMenuItem<String>(
                            value: brand,
                            child: Text(brand),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedBrand = value;
                        });
                        // Auto-trigger search with brand filter
                        if (value != null && value.isNotEmpty) {
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (_searchController.text.trim().isNotEmpty) {
                              // If there's a search query, use search API with brand filter
                              searchController.searchOffers(
                                _searchController.text,
                                brand: value,
                                category: selectedCategory,
                              );
                            } else {
                              // If no search query, use brand filter API
                              searchController.filterOffersByBrand(value);
                            }
                          });
                        } else if (_searchController.text.trim().isNotEmpty) {
                          // If brand is cleared but there's a search query, search without brand filter
                          searchController.searchOffers(
                            _searchController.text,
                            category: selectedCategory,
                          );
                        }
                      },
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Category Filter
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.category, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() => DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue[400]!),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Select Category',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...searchController.availableCategories.map((category) => 
                          DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // Price Sort Filter
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort Options Header - Horizontally Scrollable
                    SizedBox(
                      height: 40,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sort, color: Colors.purple[600], size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Sort by Price',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.star, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Sort by Rating',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.new_releases, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Newest First',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    // Sort Options - Horizontally Scrollable
                    SizedBox(
                      height: 40,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ChoiceChip(
                              label: const Text('Low → High'),
                              selected: selectedPriceOrder == 'low_high',
                              onSelected: (_) {
                                setState(() {
                                  selectedPriceOrder = 'low_high';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('High → Low'),
                              selected: selectedPriceOrder == 'high_low',
                              onSelected: (_) {
                                setState(() {
                                  selectedPriceOrder = 'high_low';
                                });
                              },
                            ),
                            if (selectedPriceOrder != 'none') ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    selectedPriceOrder = 'none';
                                  });
                                },
                                child: const Text('Clear'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              const Spacer(),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedBrand = null;
                          selectedCategory = null;
                        });
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear Filters'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (_searchController.text.trim().isNotEmpty) {
                          // Apply filters with search query
                          searchController.searchOffers(
                            _searchController.text,
                            brand: selectedBrand,
                            category: selectedCategory,
                          );
                        } else if (selectedBrand != null && selectedBrand!.isNotEmpty) {
                          // Apply brand filter without search query
                          searchController.filterOffersByBrand(selectedBrand!);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA0212),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
            onPressed: () {
              searchController.clearSearch();
              Navigator.pop(context);
            },
          ),
        ),
        title: Container(
          height: 45,
          margin: const EdgeInsets.only(right: 16, left: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F4),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search products, brands...',
              hintStyle: TextStyle(fontSize: 15, color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 22),
              suffixIcon: _searchController.text.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          searchController.clearSearch();
                          setState(() {});
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    )
                  : null,
            ),
            onSubmitted: _performSearch,
            onChanged: (value) {
              setState(() {});
              if (value.trim().isEmpty) {
                searchController.clearSearch();
              }
            },
          ),
        ),
        actions: [
          // Container(
          //   margin: const EdgeInsets.only(right: 8),
          //   decoration: BoxDecoration(
          //     color: Colors.red[50],
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: IconButton(
          //     icon: Icon(Icons.tune, color: Colors.red[600], size: 22),
          //     onPressed: () => _showFilterBottomSheet(),
          //     tooltip: 'Filter by brand and category',
          //   ),
          // ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (searchController.isSearching) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEA0212)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Searching offers...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (searchController.hasError) {
          return _buildErrorState();
        }

        if (searchController.hasResults) {
          return _buildSearchResults();
        }

        // Show "no results found" if search was performed but no results
        if (searchController.currentQuery.value.isNotEmpty && !searchController.isSearching) {
          return _buildNoResultsState();
        }

        return Obx(() => _buildInitialState());
      }),
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section


          // Search suggestions
          if (searchController.searchHistory.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.history, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: searchController.searchHistory.take(5).map((query) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = query;
                    _performSearch(query);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          query,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],

          // Active filters display
          if (selectedBrand != null || selectedCategory != null) ...[
            Row(
              children: [
                Icon(Icons.filter_alt, color: Colors.red[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Active Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (selectedBrand != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.branding_watermark, size: 16, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Text(
                          selectedBrand!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedBrand = null;
                            });
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.red[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (selectedCategory != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          selectedCategory!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory = null;
                            });
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
          ],

          // Browse by Brand section
          Obx(() {
            if (searchController.availableBrands.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.branding_watermark, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Browse by Brand',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: searchController.availableBrands.take(10).map((brand) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedBrand = brand;
                          });
                          // Use appropriate API based on whether there's a search query
                          if (_searchController.text.trim().isNotEmpty) {
                            searchController.searchOffers(
                              _searchController.text,
                              brand: brand,
                              category: selectedCategory,
                            );
                          } else {
                            searchController.filterOffersByBrand(brand);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedBrand == brand ? const Color(0xFFEA0212) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selectedBrand == brand ? const Color(0xFFEA0212) : Colors.grey[200]!,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selectedBrand == brand
                                    ? const Color(0xFFEA0212).withOpacity(0.3)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            brand,
                            style: TextStyle(
                              fontSize: 14,
                              color: selectedBrand == brand ? Colors.white : Colors.black87,
                              fontWeight: selectedBrand == brand ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search Error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    searchController.errorMessage.value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: searchController.retrySearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA0212),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry Search'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Results Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sorry, we couldn\'t find any offers matching "${searchController.currentQuery.value}"',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          searchController.clearSearch();
                          _searchController.clear();
                          setState(() {
                            selectedBrand = null;
                            selectedCategory = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Clear Search'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          _searchController.text = searchController.currentQuery.value;
                          searchController.searchOffers(searchController.currentQuery.value);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA0212),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        // Search results header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${searchController.searchResults.length} results for "${searchController.currentQuery.value}"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (searchController.hasLocation.value)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Nearby',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  // Clear brand filter button (if brand is selected)
                  if (selectedBrand != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedBrand = null;
                          });
                          // Re-search without brand filter
                          if (_searchController.text.trim().isNotEmpty) {
                            searchController.searchOffers(
                              _searchController.text,
                              category: selectedCategory,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Brand: $selectedBrand',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.close, size: 12, color: Colors.red.shade700),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Clear search button
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                    onPressed: () {
                      searchController.clearSearch();
                      _searchController.clear();
                      setState(() {
                        selectedBrand = null;
                        selectedCategory = null;
                      });
                    },
                    tooltip: 'Clear search',
                  ),
                ],
              ),
              // Active filters in results
              if (selectedBrand != null || selectedCategory != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Filters: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: [
                          if (selectedBrand != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                'Brand: $selectedBrand',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          if (selectedCategory != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                'Category: $selectedCategory',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              // Price Sort Control - Horizontally Scrollable
              SizedBox(
                height: 40,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Sort by price:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Low → High', style: TextStyle(fontSize: 12)),
                        selected: selectedPriceOrder == 'low_high',
                        onSelected: (_) {
                          setState(() {
                            selectedPriceOrder = selectedPriceOrder == 'low_high' ? 'none' : 'low_high';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('High → Low', style: TextStyle(fontSize: 12)),
                        selected: selectedPriceOrder == 'high_low',
                        onSelected: (_) {
                          setState(() {
                            selectedPriceOrder = selectedPriceOrder == 'high_low' ? 'none' : 'high_low';
                          });
                        },
                      ),
                      if (selectedPriceOrder != 'none') ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedPriceOrder = 'none';
                            });
                          },
                          child: const Text('Clear', style: TextStyle(fontSize: 12)),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Brands from search results section
        if (searchController.hasResults && searchController.availableBrands.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.branding_watermark, color: Colors.red[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Brands in "${searchController.currentQuery.value}"',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${searchController.availableBrands.length} brands',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: searchController.availableBrands.length,
                    itemBuilder: (context, index) {
                      final brand = searchController.availableBrands[index];
                      final isSelected = selectedBrand == brand;
                      
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedBrand = isSelected ? null : brand;
                            });
                            // Apply brand filter with current search query
                            if (_searchController.text.trim().isNotEmpty) {
                              searchController.searchOffers(
                                _searchController.text,
                                brand: isSelected ? null : brand,
                                category: selectedCategory,
                              );
                            } else if (!isSelected) {
                              searchController.filterOffersByBrand(brand);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEA0212) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFEA0212) : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              brand,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        
        // Search results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _getSortedResults().length,
            itemBuilder: (context, index) {
              final offer = _getSortedResults()[index];
              return _buildOfferCard(offer);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final offerId = offer['id']?.toString() ?? '0';
    
    // Get distance with proper formatting
    String? distance;
    if (offer['distance_m'] != null) {
      try {
        final distanceMeters = offer['distance_m'] is double 
            ? offer['distance_m'] 
            : double.tryParse(offer['distance_m'].toString());
        if (distanceMeters != null) {
          distance = searchController.getFormattedDistance(distanceMeters);
          log('Distance formatting: ${offer['distance_m']} -> $distance');
        }
      } catch (e) {
        log('Error formatting distance: $e');
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToOfferDetails(offerId),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Offer image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildOfferImage(offer),
                ),
                const SizedBox(width: 12),
                
                // Offer details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        offer['product_name'] ?? 'Unknown Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Offer type
                      if (offer['offer_type'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            offer['offer_type'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      
                      // Price
                      if (offer['offer_price'] != null && offer['product_price'] != null)
                        Row(
                          children: [
                            Text(
                              '₹${offer['offer_price']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${offer['product_price']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 4),
                      
                      // Distance and shop info
                      Row(
                        children: [
                          if (distance != null) ...[
                            Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 2),
                            Text(
                              distance,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (offer['shop_name'] != null)
                            Expanded(
                              child: Text(
                                offer['shop_name'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Heart icon
                Obx(() => GestureDetector(
                  onTap: () {
                    final itemData = {
                      'id': offerId,
                      'offer_id': int.tryParse(offerId) ?? 0,
                      'title': offer['product_name'] ?? 'Unknown Product',
                      'discount': offer['offer_type'] ?? 'Offer',
                      'image': offer['photo_url'],
                      'type': 'offer',
                    };
                    
                    if (favoritesController.isFavorite(offerId)) {
                      favoritesController.removeFromFavorites(offerId);
                    } else {
                      favoritesController.addToFavorites(itemData);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      favoritesController.isFavorite(offerId) 
                          ? Icons.favorite 
                          : Icons.favorite_border,
                      size: 20,
                      color: favoritesController.isFavorite(offerId) 
                          ? Colors.red 
                          : Colors.grey[600],
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build offer image widget - handles multiple images properly
  Widget _buildOfferImage(Map<String, dynamic> offer) {
    // First try to get image from 'images' array (full URLs)
    if (offer['images'] != null && offer['images'] is List && (offer['images'] as List).isNotEmpty) {
      final images = offer['images'] as List;
      final firstImageUrl = images.first.toString();
      
      return Image.network(firstImageUrl,
width: 80,
        height: 80,
        fit: BoxFit.cover,);
    }
    
    // Fallback: try to parse photo_url JSON string
    if (offer['photo_url'] != null && offer['photo_url'].toString().isNotEmpty) {
      try {
        final photoUrlString = offer['photo_url'].toString();
        
        // Check if it's a JSON array string
        if (photoUrlString.startsWith('[') && photoUrlString.endsWith(']')) {
          final List<dynamic> photoUrls = jsonDecode(photoUrlString);
          if (photoUrls.isNotEmpty) {
            final firstPhotoPath = photoUrls.first.toString();
            // Convert relative path to full URL
            final fullUrl = 'https://eastnshoptech.cloud/$firstPhotoPath';
            
            return Image.network(fullUrl,
width: 80,
              height: 80,
              fit: BoxFit.cover,);
          }
        } else {
          // Single photo URL
          return Image.network(photoUrlString,
width: 80,
            height: 80,
            fit: BoxFit.cover,);
        }
      } catch (e) {
        log('Error parsing photo_url: $e');
      }
    }
    
    // Default placeholder
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.image, size: 24, color: Colors.grey),
    );
  }
}
