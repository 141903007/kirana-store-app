import 'package:flutter/material.dart';

import '../models/customer_model.dart';
import '../models/sale_model.dart';
import '../repository/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  CustomerProvider({CustomerRepository? customerRepository})
      : _customerRepository = customerRepository ?? CustomerRepository();

  final CustomerRepository _customerRepository;

  List<CustomerListItem> customers = [];
  String searchQuery = '';
  bool isLoading = false;

  Future<void> loadCustomers() async {
    isLoading = true;
    notifyListeners();

    customers = await _customerRepository.search(query: searchQuery);

    isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    loadCustomers();
  }

  Future<CustomerModel?> getById(int id) => _customerRepository.getById(id);

  Future<double> getTotalPurchaseAmount(int customerId) =>
      _customerRepository.getTotalPurchaseAmount(customerId);

  Future<List<SaleModel>> getPurchaseHistory(int customerId) =>
      _customerRepository.getPurchaseHistory(customerId);

  Future<void> saveCustomer(CustomerModel customer) async {
    if (customer.id == null) {
      await _customerRepository.insertCustomer(customer);
    } else {
      await _customerRepository.updateCustomer(customer);
    }
    await loadCustomers();
  }

  Future<void> deleteCustomer(int id) async {
    await _customerRepository.deleteCustomer(id);
    await loadCustomers();
  }
}
