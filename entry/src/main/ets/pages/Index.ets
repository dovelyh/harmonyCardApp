import { getMockWeather, getConditionEmoji, getGradientStart, getGradientEnd, HourlyItem, DailyItem } from '../common/WeatherData';

@Entry
@Component
struct Index {
  private weather = getMockWeather();
  private now = this.weather.now;
  private hourly: HourlyItem[] = this.weather.hourly;
  private daily: DailyItem[] = this.weather.daily;

  @Builder
  StatCard(icon: string, value: string, label: string) {
    Column() {
      Text(icon).fontSize(22)
      Text(value)
        .fontSize(16)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .margin({ top: 6 })
      Text(label)
        .fontSize(11)
        .fontColor('#999999')
        .margin({ top: 2 })
    }
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .padding({ top: 14, bottom: 14 })
    .layoutWeight(1)
    .margin({ left: 4, right: 4 })
  }

  build() {
    Scroll() {
      Column() {
        Column() {
          Text(this.now.city)
            .fontSize(22)
            .fontColor('rgba(255,255,255,0.9)')
            .fontWeight(FontWeight.Medium)
            .margin({ top: 60 })
          Text(`${this.now.temp}°`)
            .fontSize(88)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .lineHeight(96)
            .margin({ top: 4 })
          Text(`${getConditionEmoji(this.now.conditionCode)} ${this.now.condition}`)
            .fontSize(20)
            .fontColor('#FFFFFF')
          Text(`体感温度 ${this.now.feelsLike}°`)
            .fontSize(15)
            .fontColor('rgba(255,255,255,0.75)')
            .margin({ top: 4 })
          Text(`最高 ${this.now.high}° / 最低 ${this.now.low}°`)
            .fontSize(15)
            .fontColor('rgba(255,255,255,0.75)')
            .margin({ top: 2, bottom: 40 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .linearGradient({
          angle: 180,
          colors: [
            [getGradientStart(this.now.conditionCode), 0.0],
            [getGradientEnd(this.now.conditionCode), 1.0]
          ]
        })

        Row() {
          this.StatCard('💧', `${this.now.humidity}%`, '湿度')
          this.StatCard('🌬️', `${this.now.windScale}级`, this.now.windDir)
          this.StatCard('☀️', `${this.now.uvIndex}`, '紫外线')
          this.StatCard('🍃', `${this.now.airIndex}`, `空气${this.now.airQuality}`)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 16 })

        Column() {
          Text('24小时预报')
            .fontSize(14)
            .fontColor('#888888')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 12 })
          Scroll() {
            Row() {
              ForEach(this.hourly, (item: HourlyItem) => {
                Column() {
                  Text(item.hour)
                    .fontSize(12)
                    .fontColor('#666666')
                  Text(getConditionEmoji(item.conditionCode))
                    .fontSize(20)
                    .margin({ top: 6, bottom: 6 })
                  Text(`${item.temp}°`)
                    .fontSize(14)
                    .fontColor('#333333')
                    .fontWeight(FontWeight.Medium)
                }
                .alignItems(HorizontalAlign.Center)
                .padding({ left: 12, right: 12 })
              })
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .padding(16)
        .margin({ left: 16, right: 16, top: 16 })

        Column() {
          Text('7天预报')
            .fontSize(14)
            .fontColor('#888888')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 4 })
          ForEach(this.daily, (item: DailyItem, index: number) => {
            Column() {
              Row() {
                Text(item.date)
                  .fontSize(15)
                  .fontColor('#333333')
                  .width(48)
                Text(getConditionEmoji(item.conditionCode))
                  .fontSize(20)
                  .margin({ left: 12 })
                Text(item.condition)
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ left: 8 })
                  .layoutWeight(1)
                Text(`${item.high}°`)
                  .fontSize(15)
                  .fontColor('#333333')
                  .fontWeight(FontWeight.Medium)
                Text(` / ${item.low}°`)
                  .fontSize(14)
                  .fontColor('#999999')
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              if (index < this.daily.length - 1) {
                Divider().strokeWidth(0.5).color('#F0F0F0')
              }
            }
          })
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .padding({ left: 16, right: 16, top: 16, bottom: 4 })
        .margin({ left: 16, right: 16, top: 16, bottom: 32 })
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F5F7FA')
    .scrollBar(BarState.Off)
  }
}