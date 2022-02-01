console.log("ip002A.js");

//検索処理
$(function(){
    $("#submit").click(function(){
      console.log("#submit")
      var shinseibi_s = $("#shinseibi_s").val();
      var shinseibi_e = $("#shinseibi_e").val();
      var hiyoubi_s = $("#hiyoubi_s").val();
      var hiyoubi_e = $("#hiyoubi_e").val();
      var shinseisya = $("#shinseisya").val();
      var kenmei = $("#kenmei").val();
      var syosai = $("#syosai").val();

      console.log("#ajax前")
      $.ajax({
        type: "POST",
        url: "/ip002A_select_js",
        dataType: "text", //dataTypeをちゃんと指定する
        data: {
          shinseibi1_s: shinseibi_s,
          shinseibi1_e: shinseibi_e,
          hiyoubi2_s: hiyoubi_s,
          hiyoubi2_e: hiyoubi_e,
          shinseisya3: shinseisya,
          kenmei4: kenmei,
          syosai5: syosai
        },
      //以下、コールバック関数で戻り値を受け取り、id="result"に表示
      success: function(json) {
      dataType: "json",  //dataTypeをちゃんと指定する
      
      //通信の確認用
      //$('#test1').append(json);

      //調査用ログ
      console.log(json);
      
      //jsonから配列にパースする。
      const json_string = JSON.parse(json);

      //調査用ログ
      // console.log(json_string);

      $('td').remove();

      var x = 0;
      json_string.forEach(i => {

        let table = document.getElementById('dataTable');
        let newRow = table.insertRow();

        //申請ID
        let newCell = newRow.insertCell();
        let newText = document.createTextNode(json_string[x].id)
        newCell.appendChild(newText);

        //申請日(yyyy/mm/dd形式に変換する。)
        newCell = newRow.insertCell();
        var shinseibi = json_string[x].申請日
        var y = shinseibi.substr(0,4);
        var m = shinseibi.substr(4,2);
        var d = shinseibi.substr(6,2);
        shinseibi_A = y + "/" + m + "/" + d;
        newText = document.createTextNode(shinseibi_A);
        newCell.appendChild(newText);

        //申請状況
        console.log(json_string[x].申請状況);
        switch(json_string[x].申請状況){
          case "1":
            var shinsei_zhokyo = "申請中"
            break;
          case "9":
            var shinsei_zhokyo = "承認済み"
        }
        newCell = newRow.insertCell();
        newText = document.createTextNode(shinsei_zhokyo);
        newCell.appendChild(newText);

        //費用発生日
        newCell = newRow.insertCell();
        var hiyoubi = json_string[x].費用発生日
        var y = hiyoubi.substr(0,4);
        var m = hiyoubi.substr(4,2);
        var d = hiyoubi.substr(6,2);
        hiyoubi_A = y + "/" + m + "/" + d;
        newText = document.createTextNode(hiyoubi_A);
        newCell.appendChild(newText);

        //申請者
        newCell = newRow.insertCell();
        newText = document.createTextNode(json_string[x].name);
        newCell.appendChild(newText);

        //件名
        newCell = newRow.insertCell();
        newText = document.createTextNode(json_string[x].件名);
        newCell.appendChild(newText);

        // //詳細
        // newCell = newRow.insertCell();
        // newText = document.createTextNode(json_string[x].詳細);
        // newCell.appendChild(newText);

        //予算コード
        newCell = newRow.insertCell();
        newText = document.createTextNode(json_string[x].予算コード);
        newCell.appendChild(newText);

        //税込額
        newCell = newRow.insertCell();
        newText = document.createTextNode(json_string[x].税込額);
        newCell.appendChild(newText);

        //カウント用
        x++;
      });

      // //テーブルにポインターを付ける
      // $("table td").css("cursor","pointer").click(function() {
      //   var tag_tr = $(this).parents()[0];
      //   var test = tag_tr.textContent;

      //   console.log("申請番号",tag_tr);
      //   console.log("申請番号",test[0]);

      //   document.getElementById('shinseisya_id_input').value = test[0];
      //   // document.getElementById('shinseisya_id').click();
      // });


      // $("table tr").click(function() {
      //     var ta = $(this)[0];
      //   //   var tb = ta.children();
      // //     var td = $(this).parents()[0];
      //     console.log('ta:' + ta.textContent);
      // //     console.log('tb:' + tb.textContent);
      // //     console.log('td:' + td.textContent);
      // //     console.log('td:' + td.innerHTML);
      // //     console.log('td:' + td.innerText);
      // }); 
      
      //行にポインターを付ける。
      $("table td").css("cursor","pointer")

      //テーブルの行を配列に詰め込み
      var data = [];
      var tr = $("table tr");//テーブルの全行を取得
      for( var i=0,l=tr.length;i<l;i++ ){
        var cells = tr.eq(i).children();//1行目から順番に列を取得(th、td)
        for( var j=0,m=cells.length;j<m;j++ ){
          if( typeof data[i] == "undefined" )
            data[i] = [];
            data[i][j] = cells.eq(j).text();//i行目j列の文字列を取得
          }
        }
      console.log(data)

      $('td').click(function(){
        //縦
        var row = $(this).closest('tr').index();
        //横
        var col = this.cellIndex;
        console.log('Row: ' + row + ', Column: ' + col);

        //何故かarrayに入れるときに1行目が空白になるので+1する。
        shinsei_no = data[row+1][0]
        console.log('申請No' + shinsei_no)
        document.getElementById('shinseisya_id_input').value = shinsei_no;
        document.getElementById('shinseisya_id').click();
      });




      $("table tr").click(function() {
          var ta = $(this)[0];
        //   var tb = ta.children();
      //     var td = $(this).parents()[0];
          console.log('ta:' + ta.textContent);
      //     console.log('tb:' + tb.textContent);
      //     console.log('td:' + td.textContent);
      //     console.log('td:' + td.innerHTML);
      //     console.log('td:' + td.innerText);
      });



      const position = $('#submit').offset().top;
      // $(window).scrollTop(500);
      $("html,body").animate({scrollTop:position},600);

      },
      error: function() {
      $('#result1').append('error');
      }

      });
    });
});