var yosan = "ipYosanChart1.txt";
getApiData(function (data) {
  console.log(data);
});

function getApiData(callback){
  $.ajax({
    type: "POST",
    url: "/ip082_yosan",
    dataType: "text", //dataTypeをちゃんと指定する
    data: {
      yosan: yosan
    },
    //以下、コールバック関数で戻り値を受け取り、id="result"に表示
    success: function (json) {
      dataType: "json",  //dataTypeをちゃんと指定する
    
      //通信の確認用
      console.log(json);
    
      //jsonから配列にパースする。
      const json_string = JSON.parse(json);
      console.log(json_string);
    
      var x = 0;
      json_string.forEach(i => {
        //変数を定義する。
        var chart_buppin = 0
        var syareikin = 0
        var ryohi = 0
        var syoseki = 0
        var kyoiku = 0
        var kousaihi = 0
      
        switch (json_string[x].費用区分){
        
          case "1":
            document.getElementById('chart_buppin').value = -(json_string[x].sum);
          break;
          case "2":
            document.getElementById('chart_syareikin').value = -(json_string[x].sum);
          break;
          case "3":
            document.getElementById('chart_ryohi').value = -(json_string[x].sum);
          break;
          case "4":
            document.getElementById('chart_syoseki').value = -(json_string[x].sum);
          break;
          case "5":
            document.getElementById('chart_kyoiku').value = -(json_string[x].sum);
          break;
          case "6":
            document.getElementById('chart_kousaihi').value = -(json_string[x].sum);
          break;
        }
        console.log(json_string[x].sum);
        x++;
      });
      initUser();
      console.log("initUserメソッド内");
      callback(json_string[x].sum);
    },
    error: function () {
      console.log("接続失敗");
    }
  
  });
}

function initUser(){
  console.log("initUser");
  
  //パラメタ領域から値を取得
  var chart_array = [
  Number($('#chart_buppin').val()),
  Number($('#chart_syareikin').val()),
  Number($('#chart_ryohi').val()),
  Number($('#chart_syoseki').val()),
  Number($('#chart_kyoiku').val()),
  Number($('#chart_kousaihi').val())]
  console.log(`${chart_array}`);

  //合計金額を集計
  var sum = 0.
  var x = 0;
  chart_array.forEach(i => {
    sum = sum + chart_array[x];
    x++;
  });
  console.log(`合計${sum}`);

  //合計金額に対して明細の割合を計算する。
  var chart_buppin = ((chart_array[0]/sum) * 100).toFixed(0)
  var chart_syareikin = ((chart_array[1]/sum) * 100).toFixed(0)
  var chart_ryohi = ((chart_array[2]/sum) * 100).toFixed(0)
  var chart_syoseki = ((chart_array[3]/sum) * 100).toFixed(0)
  var chart_kyoiku = ((chart_array[4]/sum) * 100).toFixed(0)
  var chart_kousaihi = ((chart_array[5]/sum) * 100).toFixed(0)

  // Set new default font family and font color to mimic Bootstrap's default styling
  Chart.defaults.global.defaultFontFamily = 'Nunito', '-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';
  Chart.defaults.global.defaultFontColor = '#858796';

  // Pie Chart Example
  var ctx = document.getElementById("myPieChart");
  var myPieChart = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: ["物品", "謝礼金", "旅費", "書籍", "教育受講", "交際費",],
      datasets: [{
        data: [chart_buppin, chart_syareikin, chart_ryohi, chart_syoseki, chart_kyoiku, chart_kousaihi],
        backgroundColor: ['#F25E5E', '#F2AF5C', '#04BFAD','#F28963', '#658CBF', '#0396A6'],
        hoverBackgroundColor: ['#2e59d9','#2e59d9','#2e59d9','#2e59d9','#2e59d9','#2e59d9'],
        hoverBorderColor: "rgba(234, 236, 244, 1)",
      }],
    },
    options: {
      maintainAspectRatio: false,
      tooltips: {
        backgroundColor: "rgb(255,255,255)",
        bodyFontColor: "#858796",
        borderColor: '#dddfeb',
        borderWidth: 1,
        xPadding: 15,
        yPadding: 15,
        displayColors: false,
        caretPadding: 10,
        bodyFontSize: 16,
      },
      legend: {
        display: false
      },
      cutoutPercentage: 80,
    },
  });

}