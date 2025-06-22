import 'package:readeck_app/utils/network_error_exception.dart';

class ResourceNotFoundException extends NetworkErrorException {
  const ResourceNotFoundException(super.message, super.uri, super.statusCode);
}
