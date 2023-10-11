// ignore_for_file: unnecessary_null_comparison

import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector64;


class Custom3dObjectScreen extends StatefulWidget
{
  const Custom3dObjectScreen({super.key});

  @override
  State<Custom3dObjectScreen> createState() => _Custom3dObjectScreenState();
}

// https://firebasestorage.googleapis.com/v0/b/push-notification-app-3db9a.appspot.com/o/blinds.glb?alt=media&token=4a67e8d8-e30f-4110-9158-7dc9c433224c&_gl=1*w0rmc5*_ga*NTcwOTE2NzkwLjE2OTcwMjk5ODM.*_ga_CW55HF8NVT*MTY5NzAyOTk4My4xLjEuMTY5NzAzMDA4NS4yMi4wLjA.
//https://firebasestorage.googleapis.com/v0/b/push-notification-app-3db9a.appspot.com/o/window_blinds_low_poly_3d_model.glb?alt=media&token=5f7f9510-495c-4ba4-ad7c-7a94de96ed33&_gl=1*1ju0wag*_ga*NTcwOTE2NzkwLjE2OTcwMjk5ODM.*_ga_CW55HF8NVT*MTY5NzAyOTk4My4xLjEuMTY5NzAzMDU4Ni4yMi4wLjA.
class _Custom3dObjectScreenState extends State<Custom3dObjectScreen>
{
  ARSessionManager? sessionManager;
  ARObjectManager? objectManager;
  ARAnchorManager? anchorManager;


  List<ARNode> allNodes = [];
  List<ARAnchor> allAnchor = [];

  whenARViewCreated(ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager)
  {
    sessionManager = arSessionManager;
    objectManager = arObjectManager;
    anchorManager = arAnchorManager;

    sessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
    );
    objectManager!.onInitialize();

    sessionManager!.onPlaneOrPointTap = whenPlaneDetectedAndUserTapped;
    objectManager!.onPanStart = whenOnPanStarted;
    objectManager!.onPanChange = whenOnPanChanged;
    objectManager!.onPanEnd = whenOnPanEnded;
    objectManager!.onRotationStart = whenOnRotationStarted;
    objectManager!.onRotationChange = whenOnRotationChanged;
    objectManager!.onRotationEnd = whenOnRotationEnded;
  }

  whenOnPanStarted(String node3dObjectName)
  {
    print("Started Panning Node = " + node3dObjectName);
  }

  whenOnPanChanged(String node3dObjectName)
  {
    print("Continued Panning Node = " + node3dObjectName);
  }

  whenOnPanEnded(String node3dObjectName, Matrix4 transform)
  {
    print("Ended Panning Node = " + node3dObjectName);

    final pannedNode = allNodes.firstWhere((node) => node.name == node3dObjectName);
  }

  whenOnRotationStarted(String node3dObjectName)
  {
    print("Started Rotating Node = " + node3dObjectName);
  }

  whenOnRotationChanged(String node3dObjectName)
  {
    print("Continued Rotating Node = " + node3dObjectName);
  }

  whenOnRotationEnded(String node3dObjectName, Matrix4 transform)
  {
    print("Ended Rotating Node = " + node3dObjectName);

    final pannedNode = allNodes.firstWhere((node) => node.name == node3dObjectName);
  }

  Future<void> whenPlaneDetectedAndUserTapped(List<ARHitTestResult> tapResults) async
  {
    var userHitTestResult = tapResults.firstWhere((userTap) => userTap.type == ARHitTestResultType.plane);

    if(userHitTestResult != null)
    {
      //new anchor
      var newPlaneARAnchor = ARPlaneAnchor(transformation: userHitTestResult.worldTransform);

      bool? isAnchorAdded = await anchorManager!.addAnchor(newPlaneARAnchor);

      if(isAnchorAdded!)
      {
        allAnchor.add(newPlaneARAnchor);

        //new node
        var nodeNew3dObject = ARNode(
          type: NodeType.localGLTF2, //.glb 3d model //size upto 30MB or lower than 30
          uri: "assets/window_blinds/scene.gltf",
          scale: vector64.Vector3(0.005, 0.02, 0.02),
          position: vector64.Vector3(0, 0, 0),
          rotation: vector64.Vector4(1.0, 0, 0, 0),
        );

        bool? isNewNodeAddedToNewAnchor = await objectManager!.addNode(nodeNew3dObject, planeAnchor: newPlaneARAnchor);

        if(isNewNodeAddedToNewAnchor!)
        {
          allNodes.add(nodeNew3dObject);
        }
        else
        {
          sessionManager!.onError("Attaching Node to Anchor Failed.");
        }
      }
      else
      {
        sessionManager!.onError("Adding Anchor Failed.");
      }
    }
  }

  Future<void> removeEveryObject() async
  {
    allAnchor.forEach((eachAnchor)
    {
      anchorManager!.removeAnchor(eachAnchor);
    });

    allAnchor = [];
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    sessionManager!.dispose();
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Custom 3d Objects"
        ),
        centerTitle: true,
      ),
      body: SizedBox(
        child: Stack(
          children: [
            ARView(
              planeDetectionConfig: PlaneDetectionConfig.horizontal,
              onARViewCreated: whenARViewCreated,

            ),
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: Align(
                alignment: FractionalOffset.bottomRight,
                child: ElevatedButton(
                  onPressed: ()
                  {
                    removeEveryObject();
                  },
                  child: const Text(
                    "Remove"
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
