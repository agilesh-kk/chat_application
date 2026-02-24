void main(){
  print(generateConversationId("6J5UbpWoQ8OnEqOy8sOBPBiPeXk2", "qcEGPLzpvmOh4m9zmiCz8oC0Zwv1"));
}

String generateConversationId(String user1,String user2){
    final sorted = [user1, user2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }