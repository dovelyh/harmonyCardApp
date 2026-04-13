const storage = new LocalStorage();

@Entry(storage)
@Component
struct WidgetCard {
  @LocalStorageProp('dimension') dimension: number = 2;
  @LocalStorageProp('city') city: string = '合肥';
  @LocalStorageProp('temp') temp: number = 26;
  @LocalStorageProp('condition') condition: string = '晴';
  @LocalStorageProp('conditionEmoji') conditionEmoji: string = '☀️';
  @LocalStorageProp('gradientStart') gradientStart: string = '#1A6DB5';
  @LocalStorageProp('gradientEnd') gradientEnd: string = '#81CCFF';
  @LocalStorageProp('high') high: number = 29;
  @LocalStorageProp('low') low: number = 18;
  @LocalStorageProp('humidity') humidity: number = 45;
  @LocalStorageProp('windDir') windDir: string = '东南风';
  @LocalStorageProp('windScale') windScale: number = 3;
  @LocalStorageProp('airQuality') airQuality: string = '优';
  @LocalStorageProp('airIndex') airIndex: number = 42;
  @LocalStorageProp('uvIndex') uvIndex: number = 5;
  @LocalStorageProp('feelsLike') feelsLike: number = 28;
  @LocalStorageProp('hourlyJson') hourlyJson: string = '[]';
  @LocalStorageProp('dailyJson') dailyJson: string = '[]';

  private doAction(): void {
    postCardAction(this, {
      action: 'router',
      abilityName: 'EntryAbility',
      params: { from: 'widget' }
    });
  }

  @Builder
  StatItem(icon: string, value: string, label: string) {
    Column() {
      Text(icon).fontSize(18)
      Text(value)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .margin({ top: 4 })
      Text(label)
        .fontSize(10)
        .fontColor('rgba(255,255,255,0.65)')
        .margin({ top: 2 })
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }

  // 1×2：极简横条
  @Builder
  build1x2() {
    Row() {
      Column() {
        Text(this.city)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.8)')
        Text(`${this.conditionEmoji} ${this.condition}`)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(`${this.temp}°`)
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .linearGradient({
      angle: 135,
      colors: [[this.gradientStart, 0.0], [this.gradientEnd, 1.0]]
    })
    .borderRadius(16)
    .onClick(() => this.doAction())
  }

  // 2×2：标准方块
  @Builder
  build2x2() {
    Column() {
      Text(this.city)
        .fontSize(13)
        .fontColor('rgba(255,255,255,0.8)')
        .alignSelf(ItemAlign.Start)

      Row() {
        Text(`${this.temp}°`)
          .fontSize(52)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text(this.conditionEmoji)
          .fontSize(36)
          .margin({ left: 8, top: 8 })
      }
      .margin({ top: 4 })

      Blank()

      Row() {
        Text(`↑${this.high}° ↓${this.low}°`)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.85)')
        Blank()
        Text(this.airQuality)
          .fontSize(11)
          .fontColor('#FFFFFF')
          .backgroundColor('rgba(255,255,255,0.25)')
          .borderRadius(8)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .linearGradient({
      angle: 135,
      colors: [[this.gradientStart, 0.0], [this.gradientEnd, 1.0]]
    })
    .borderRadius(16)
    .onClick(() => this.doAction())
  }

  // 2×4：宽矩形
  @Builder
  build2x4() {
    Row() {
      Column() {
        Text(this.city)
          .fontSize(13)
          .fontColor('rgba(255,255,255,0.8)')
          .alignSelf(ItemAlign.Start)
        Text(`${this.temp}°`)
          .fontSize(52)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ top: 2 })
        Text(`${this.conditionEmoji} ${this.condition}`)
          .fontSize(14)
          .fontColor('#FFFFFF')
        Text(`↑${this.high}° ↓${this.low}°`)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.8)')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(45)
      .height('100%')
      .padding({ left: 14 })

      Divider()
        .vertical(true)
        .strokeWidth(1)
        .color('rgba(255,255,255,0.2)')
        .height('70%')
        .alignSelf(ItemAlign.Center)

      Column() {
        Column() {
          Text(`💧 ${this.humidity}%`)
            .fontSize(13)
            .fontColor('#FFFFFF')
          Text(`🌬️ ${this.windDir}${this.windScale}级`)
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.8)')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)

        Divider()
          .strokeWidth(1)
          .color('rgba(255,255,255,0.2)')
          .margin({ top: 8, bottom: 8 })

        ForEach((JSON.parse(this.hourlyJson) as HourlyCardItem[]).slice(0, 3),
          (item: HourlyCardItem) => {
            Row() {
              Text(item.hour)
                .fontSize(11)
                .fontColor('rgba(255,255,255,0.7)')
                .width(44)
              Text(`${item.temp}°`)
                .fontSize(13)
                .fontColor('#FFFFFF')
                .textAlign(TextAlign.End)
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 4 })
          })
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(55)
      .height('100%')
      .padding({ left: 12, right: 14 })
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 135,
      colors: [[this.gradientStart, 0.0], [this.gradientEnd, 1.0]]
    })
    .borderRadius(16)
    .onClick(() => this.doAction())
  }

  // 4×4：大方块
  @Builder
  build4x4() {
    Column() {
      Row() {
        Text(this.city)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
        Blank()
        Text(this.airQuality)
          .fontSize(11)
          .fontColor('#FFFFFF')
          .backgroundColor('rgba(255,255,255,0.25)')
          .borderRadius(10)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
      }
      .width('100%')

      Row() {
        Column() {
          Text(`${this.temp}°`)
            .fontSize(64)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .lineHeight(68)
          Text(`体感 ${this.feelsLike}°`)
            .fontSize(13)
            .fontColor('rgba(255,255,255,0.8)')
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Column() {
          Text(this.conditionEmoji)
            .fontSize(48)
          Text(this.condition)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .margin({ top: 8 })

      Text(`↑${this.high}° ↓${this.low}°`)
        .fontSize(14)
        .fontColor('rgba(255,255,255,0.85)')
        .alignSelf(ItemAlign.Start)
        .margin({ top: 4 })

      Row() {
        this.StatItem('💧', `${this.humidity}%`, '湿度')
        this.StatItem('🌬️', `${this.windScale}级`, this.windDir)
        this.StatItem('☀️', `${this.uvIndex}`, 'UV')
        this.StatItem('🍃', `${this.airIndex}`, 'AQI')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .backgroundColor('rgba(0,0,0,0.15)')
      .borderRadius(12)
      .padding({ top: 10, bottom: 10, left: 8, right: 8 })
      .margin({ top: 12 })

      Blank()

      Row() {
        ForEach((JSON.parse(this.dailyJson) as DailyCardItem[]).slice(0, 5),
          (item: DailyCardItem) => {
            Column() {
              Text(item.date)
                .fontSize(11)
                .fontColor('rgba(255,255,255,0.7)')
              Text(`${item.high}°`)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Medium)
                .margin({ top: 4 })
              Text(`${item.low}°`)
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.6)')
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .linearGradient({
      angle: 135,
      colors: [[this.gradientStart, 0.0], [this.gradientEnd, 1.0]]
    })
    .borderRadius(16)
    .onClick(() => this.doAction())
  }

  // 6×4：全量看板
  @Builder
  build6x4() {
    Column() {
      Row() {
        Column() {
          Text(this.city)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .alignSelf(ItemAlign.Start)

          Row() {
            Text(`${this.temp}°`)
              .fontSize(60)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .lineHeight(64)
            Text(this.conditionEmoji)
              .fontSize(40)
              .margin({ left: 8, top: 10 })
          }
          .margin({ top: 4 })

          Text(`${this.condition}  体感${this.feelsLike}°`)
            .fontSize(14)
            .fontColor('rgba(255,255,255,0.85)')
          Text(`↑${this.high}° ↓${this.low}°`)
            .fontSize(13)
            .fontColor('rgba(255,255,255,0.8)')
            .margin({ top: 4 })

          Blank()

          Row() {
            this.StatItem('💧', `${this.humidity}%`, '湿度')
            this.StatItem('🌬️', `${this.windScale}级`, '风力')
            this.StatItem('🍃', `${this.airIndex}`, 'AQI')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .backgroundColor('rgba(0,0,0,0.15)')
          .borderRadius(10)
          .padding({ top: 8, bottom: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(4)
        .height('100%')
        .padding({ right: 12 })

        Divider()
          .vertical(true)
          .strokeWidth(1)
          .color('rgba(255,255,255,0.2)')
          .height('90%')
          .alignSelf(ItemAlign.Center)

        Column() {
          ForEach(JSON.parse(this.dailyJson) as DailyCardItem[],
            (item: DailyCardItem) => {
              Row() {
                Text(item.date)
                  .fontSize(12)
                  .fontColor('rgba(255,255,255,0.8)')
                  .width(36)
                Blank()
                Text(item.condition)
                  .fontSize(11)
                  .fontColor('rgba(255,255,255,0.7)')
                Blank()
                Text(`${item.high}°`)
                  .fontSize(13)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Medium)
                Text(`/${item.low}°`)
                  .fontSize(12)
                  .fontColor('rgba(255,255,255,0.6)')
                  .margin({ left: 4 })
              }
              .width('100%')
              .margin({ bottom: 6 })
            })
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.SpaceEvenly)
        .layoutWeight(3)
        .height('100%')
        .padding({ left: 12 })
      }
      .width('100%')
      .layoutWeight(1)

      Divider()
        .strokeWidth(1)
        .color('rgba(255,255,255,0.2)')
        .margin({ top: 8, bottom: 8 })

      Row() {
        ForEach((JSON.parse(this.hourlyJson) as HourlyCardItem[]).slice(0, 6),
          (item: HourlyCardItem) => {
            Column() {
              Text(item.hour)
                .fontSize(11)
                .fontColor('rgba(255,255,255,0.7)')
              Text(`${item.temp}°`)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Medium)
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .linearGradient({
      angle: 135,
      colors: [[this.gradientStart, 0.0], [this.gradientEnd, 1.0]]
    })
    .borderRadius(16)
    .onClick(() => this.doAction())
  }

  build() {
    if (this.dimension === 1) {
      this.build1x2();
    } else if (this.dimension === 2) {
      this.build2x2();
    } else if (this.dimension === 4) {
      this.build2x4();
    } else if (this.dimension === 5) {
      this.build4x4();
    } else if (this.dimension === 6) {
      this.build6x4();
    } else {
      this.build2x2();
    }
  }
}

interface HourlyCardItem {
  hour: string;
  temp: number;
  conditionCode: number;
}

interface DailyCardItem {
  date: string;
  high: number;
  low: number;
  conditionCode: number;
  condition: string;
}
