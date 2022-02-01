class ipYosanMeisyo{
  constructor() {
    console.log("ipyosanmeisyo.js");
  }
  
  info(){
    console.log("ipyosanmeisyo.js");

    var yosan_code = "A1001"

    $.ajax({
      type: "POST",
      url: "/ip081A_yosan_meisyo",
      dataType: "text", //dataTypeをちゃんと指定する
      data: {
        yosan_code: yosan_code
      },
      //以下、コールバック関数で戻り値を受け取り、id="result"に表示
      success: function (json) {
        dataType: "json",  //dataTypeをちゃんと指定する
      
          console.log(json);
      
        //jsonから配列にパースする。
        const json_string = JSON.parse(json);
        console.log(json_string);

      },
      error: function () {
        $('#result1').append('error');
      }
    });
  }
}
//クラスエクスポート
export default ipYosanMeisyo;