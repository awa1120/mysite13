console.log("ip001A.js_import前");
// import ipYosanMeisho from "./ipYosanMeisho";
console.log("ip001A.js_import後");

// //予算名称取得サブルーチンを呼び出す
// const ipYosanMeisho = new ipYosanMeisho();
// ipYosanMeisho.info();

// 画面中間データ引き渡し
//↓の取得でHTML丸ごと持ってくる。
//ログで見るとこんな感じ[<input type="text" id="gamen_param" placeholder="" name="zeigaku" maxlength="10" value="1">]
var gamen_param = document.getElementById('gamen_param');
var gamen_param_value = gamen_param.value;

//申請Noを取得する
var shinsei_no = document.getElementById('shinsei_no');
var shinsei_no_value = shinsei_no.value;

//権限を取得する。
var authority = document.getElementById('authority');
var authority_value = authority.value;

console.log(`データ${authority}`);
console.log(`データ${authority_value}`);

initUser();

function initUser(){
  //画面パラメタが[1]だった場合、検索画面からの遷移である。
  if (gamen_param_value == 1) {
    $(".form-1").prop("disabled", true);
    $("#shinsei").addClass("display_none");
    $("#img_form").addClass("display_none");
    //承認権限ありの場合以外、承認ボタンを表示する。
    if (authority_value　!= "0010"){
      $("#syonin").addClass("display_none");
      $(".syonin_area").addClass("display_none");
    }
  }else if(gamen_param_value == 0){
    //メニューから遷移してきた場合
    //当日の日付を取得し、申請日・費用発生日に入力する。
    var hiduke=new Date(); 
    var year = hiduke.getFullYear();
    var month = ('00' + (hiduke.getMonth()+1)).slice(-2);
    var day = ('00' + hiduke.getDate()).slice(-2);

    today = year + "/" + month  + "/" + day;
    document.getElementById('shinseibi').value = today;
    document.getElementById('hiyoubi').value = today;
    //決め打ちで予算コードを入力しておく。いずれは利用者に応じて権限で設定できるようにする。
    document.getElementById('yosan_code').value = "A1001";
    
    //更新用のボタン・項目は非表示にする。
    $("#shinsei_torimodoshi").addClass("display_none");
    $("#syonin").addClass("display_none");
    $("#img_view").addClass("display_none");
    $(".syonin_area").addClass("display_none");
    $("#shisei_no").addClass("display_none");
  }
}

$.ajax({
  type: "POST",
  url: "/ip001A_select_js",
  dataType: "text", //dataTypeをちゃんと指定する
  data: {
    shinsei_no_value: shinsei_no_value
  },
  //以下、コールバック関数で戻り値を受け取り、id="result"に表示
  success: function (json) {
    dataType: "json",  //dataTypeをちゃんと指定する

      //通信の確認用
      //$('#test1').append(json);
      console.log(json);

    //jsonから配列にパースする。
    const json_string = JSON.parse(json);
    console.log(json_string);
    
    //ここから各項目erbの入力項目に入れていく。
    switch (json_string[0].申請状況){
      //文字列にしなければ条件判断されない
      case "1":
        var shinsei_zhokyo = "申請中";
      break;
      case "9":
        var shinsei_zhokyo = "承認済み";
        //承認済みの場合は、「承認」ボタンを非表示にする。
        $("#syonin").addClass("display_none");
      break;
    }
    document.getElementById('shisei_zyokyo').innerText = `申請状況：${shinsei_zhokyo}`;
    document.getElementById('shinseisya').value = json_string[0].申請者id;
    document.getElementById('shinseibi').value = json_string[0].申請日;
    document.getElementById('hiyoubi').value = json_string[0].費用発生日;
    document.getElementById('hiyou_kubun').value = json_string[0].費用区分;
    document.getElementById('kenmei').value = json_string[0].件名;
    document.getElementById('syosai').value = json_string[0].詳細;
    document.getElementById('yosan_code').value = json_string[0].予算コード;
    document.getElementById('zeikomi').value = json_string[0].税込額;
    document.getElementById('zeinuki').value = json_string[0].税抜額;
    document.getElementById('zeigaku').value = json_string[0].税額;
    document.getElementById('bikou').value = json_string[0].備考;
    //添付ファイル
    if(json_string[0].添付ファイル!=null){
      var img = document.getElementById('img');
      //ディレクトリを設定する。
      var file = json_string[0].添付ファイル
      img.href = file;
      //ディレクトリを削除しファイル名のみにする。
      var file_name = file.slice(6);
      $('#img').text(file_name);
      console.log(json_string[0].添付ファイル);
    }else{
      $('#img').hide();
    }

  },
  error: function () {
    $('#result1').append('error');
  }

});

$(function() {
  // テキストボックスにフォーカス時、フォームの背景色を変化
  $('#zeikomi')
    .focusin(function(e) {
      $(this).css('background-color', '#ffc');
      console.log("フォーカスイン")
    })
    //税額計算
    .focusout(function(e) {
      $(this).css('background-color', '');
      console.log("フォーカスアウト")
      var zeikomi = document.getElementById('zeikomi').value;

      //切り上げ計算
      var zeigaku = zeikomi / 1.1;
      document.getElementById('zeinuki').value = Math.ceil(zeigaku);

      var zeinuki = zeikomi - zeigaku;
      document.getElementById('zeigaku').value = Math.floor(zeinuki);

      console.log(`${zeikomi}`);
    });

    $('#test').click(function(){
      shinseibi = document.getElementById('shinseibi').value;

      console.log(shinseibi);

    });
});

