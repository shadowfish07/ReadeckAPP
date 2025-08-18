import 'package:result_dart/result_dart.dart';
import '../../service/update_service.dart';
import '../../../domain/models/update/update_info.dart';

class UpdateRepository {
  final UpdateService _updateService;

  UpdateRepository(this._updateService);

  AsyncResult<UpdateInfo> checkForUpdate() async {
    try {
      final updateInfo = await _updateService.checkForUpdate();
      if (updateInfo != null) {
        return Success(updateInfo);
      } else {
        return Failure(Exception("No update available"));
      }
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
