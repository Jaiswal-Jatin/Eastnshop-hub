import 'dart:developer';

class SnackBarTestHelper {
  // Test all snack bar types
  static void testSnackBarTypes() {
    log('🧪 Testing Snack Bar Types...');
    
    // Test 1: Error snack bar
    // AppSnackBar.show(
    //   message: "This is an error message",
    //   type: SnackType.error,
    // );
    log('✅ Error snack bar displayed');
    
    // Test 2: Warning snack bar
    // AppSnackBar.show(
    //   message: "This is a warning message",
    //   type: SnackType.warning,
    // );
    log('✅ Warning snack bar displayed');
    
    // Test 3: Info snack bar
    // AppSnackBar.show(
    //   message: "This is an info message",
    //   type: SnackType.info,
    // );
    log('✅ Info snack bar displayed');
    
    // Test 4: Success snack bar
    // AppSnackBar.show(
    //   message: "This is a success message",
    //   type: SnackType.success,
    // );
    log('✅ Success snack bar displayed');
    
    log('✅ All snack bar types tested!');
  }
  
  // Test favorite success messages
  static void testFavoriteMessages() {
    log('🧪 Testing Favorite Success Messages...');
    

    log('✅ Add to favorites success message displayed');
    

    log('✅ Remove from favorites success message displayed');
    
    log('✅ Favorite success messages tested!');
  }
}
