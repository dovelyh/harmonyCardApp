/**
 * WidgetCard.ets — 服务卡片 UI
 *
 * ============================================================
 * 【核心概念：卡片的运行环境】
 * ============================================================
 * 服务卡片不运行在元服务自身的进程里，而是运行在桌面（Launcher）进程的沙箱中。
 * 这意味着：
 *   ✅ 支持：文本/图片/布局/点击事件/LinearGradient 等基础 ArkUI 组件和修饰符
 *   ❌ 不支持：AVPlayer（音频）、网络请求、大多数系统 API
 *
 * 卡片 UI 通过 formBindingData（由 EntryFormAbility 提供）初始化数据，
 * 通过 @LocalStorageProp 读取这些数据，并随数据变化自动重绘。
 *
 * ============================================================
 * 【LocalStorage 机制】
 * ============================================================
 * FormKit 在卡片创建时会将 FormBindingData 的字段注入一个 LocalStorage 实例，
 * 并把这个实例与卡片组件绑定。
 *
 *   const storage = new LocalStorage();  // 声明一个 LocalStorage 实例
 *   @Entry(storage)                      // 将该实例绑定到本 @Entry 组件
 *
 * @LocalStorageProp('key') 装饰器：
 *   - 从绑定的 LocalStorage 中读取对应 key 的值
 *   - 当 FormAbility 调用 formProvider.updateForm 更新数据时，
 *     LocalStorage 中对应 key 的值会更新，组件自动重渲染
 *   - 右侧的赋值是默认值，仅在 LocalStorage 中没有该 key 时生效
 */

/**
 * LocalStorage 实例必须在组件外部声明为模块级变量。
 * 原因：@Entry(storage) 装饰器需要在编译期绑定，不能在运行时动态创建。
 */
const storage = new LocalStorage();

/**
 * @Entry(storage) — 将本组件声明为卡片的根入口，并绑定上方的 LocalStorage 实例。
 * @Component — 声明这是一个 ArkUI 组件，拥有完整的组件生命周期。
 *
 * 注意：卡片只能有一个 @Entry 组件，即 WidgetCard 本身就是整张卡片的根。
 */
@Entry(storage)
@Component
struct WidgetCard {
  // ============================================================
  // 【数据接收：@LocalStorageProp】
  // ============================================================
  // 每个 @LocalStorageProp 对应 EntryFormAbility 注入的同名字段。
  // 当 FormAbility 调用 updateForm 时，这些值会自动更新并触发重渲染。
  // 右侧的值是默认值，防止数据还未到达时 UI 崩溃。

  @LocalStorageProp('dimension') dimension: number = 2;       // 卡片规格编号
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
  // 数组类型不能直接通过 LocalStorage 传递，序列化为 JSON 字符串存储，
  // 在 @Builder 里用 JSON.parse 还原。
  @LocalStorageProp('hourlyJson') hourlyJson: string = '[]';
  @LocalStorageProp('dailyJson') dailyJson: string = '[]';
  @LocalStorageProp('meritCount') meritCount: number = 0;

  /**
   * doAction — 点击卡片左侧（天气区域）时触发，打开元服务主界面
   *
   * postCardAction 是卡片专用的交互 API，支持三种 action：
   *
   *   'router' → 启动（或切换到前台）指定的 UIAbility，并可传参。
   *              系统会调用目标 Ability 的 onCreate 或 onNewWant。
   *              效果：从桌面卡片跳转到元服务主界面。
   *
   *   'message' → 向本卡片的 FormExtensionAbility 发送消息，
   *               触发 onFormEvent(formId, message)。
   *               后台静默处理，不打开 UI。（本项目木鱼用此方式）
   *
   *   'call' → 调用后台 UIAbility 的方法（需要 Ability 在后台运行），
   *            用于静默后台操作，本项目未使用。
   */
  private doAction(): void {
    postCardAction(this, {
      action: 'router',
      abilityName: 'EntryAbility',   // 目标 Ability 名称，与 module.json5 中配置一致
      params: { from: 'widget' }     // 自定义参数，EntryAbility 可在 want.parameters 中读取
    });
  }

  /**
   * doKnock — 点击卡片右侧（木鱼区域）时触发，敲击木鱼
   *
   * 使用 'message' action：不打开主界面，静默通知 FormAbility。
   * FormAbility 的 onFormEvent 收到 { type: 'knock' } 后：
   *   1. 功德数 +1，写入 preferences
   *   2. 调用 formProvider.updateForm 更新所有卡片的 meritCount 显示
   *
   * 为什么不在卡片里直接改 this.meritCount？
   * 卡片的 @LocalStorageProp 由 FormAbility 控制，卡片不能主动写入 LocalStorage。
   * 只有 FormAbility 通过 formProvider.updateForm 推送新数据，卡片才会更新。
   */
  private doKnock(): void {
    postCardAction(this, {
      action: 'message',
      params: { type: 'knock' }
    });
  }

  /**
   * FishContent — 木鱼面板的 UI 内容（@Builder 可复用片段）
   *
   * @Builder 装饰器：
   *   - 定义一段可复用的 UI 片段，类似函数式组件
   *   - 不是独立的 Component，没有自己的生命周期，渲染到调用方的容器中
   *   - 支持参数，但参数变化不会单独触发重渲染（父组件重渲染时整体刷新）
   *   - 在 build() 或其他 @Builder 中调用：this.FishContent(36, 13)
   *
   * 为什么不把木鱼面板提取成独立 @Component？
   * 卡片场景中，独立 @Component 增加渲染层级，且木鱼面板很简单，
   * 用 @Builder 足够，避免过度拆分。
   *
   * @param circleSize  圆形背景的尺寸（fp），不同规格卡片大小不同
   * @param countSize   功德数字的字号（fp）
   */
  @Builder
  FishContent(circleSize: number, countSize: number) {
    // Stack 是层叠布局容器，子元素按声明顺序从下到上叠加。
    // 这里用于把"木鱼"文字叠加在圆形背景上方。
    Stack() {
      Circle()
        .width(circleSize)
        .height(circleSize)
        .fill('#FFD700')   // 金色圆形背景
        .opacity(0.25)     // 低透明度，营造柔和光晕效果
      Text('木鱼')
        .fontSize(circleSize * 0.28)   // 字号随圆圈尺寸等比缩放
        .fontColor('#FFE066')
        .fontWeight(FontWeight.Bold)
    }
    // @Builder 内的组件直接渲染到父容器，这里的 Text 和上面的 Stack 是同级的，
    // 父容器（Column）会将它们垂直排列。
    Text(`${this.meritCount}`)
      .fontSize(countSize)
      .fontColor('#FFFFFF')
      .fontWeight(FontWeight.Bold)
      .margin({ top: 6 })
    Text('功德')
      .fontSize(countSize * 0.65)
      .fontColor('rgba(255,255,255,0.7)')
      .margin({ top: 2 })
  }

  /**
   * StatItem — 统计数据项（湿度/风力/UV/AQI）的 @Builder
   *
   * layoutWeight：在 Flex/Row/Column 布局中，按权重分配剩余空间。
   * 4个 StatItem 各设 layoutWeight(1)，则均分父容器宽度（各占 25%）。
   */
  @Builder
  StatItem(icon: string, value: string, label: string) {
    Column() {
      Text(icon).fontSize(16)
      Text(value)
        .fontSize(11)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .margin({ top: 2 })
      Text(label)
        .fontSize(9)
        .fontColor('rgba(255,255,255,0.65)')
        .margin({ top: 1 })
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)   // 均分父 Row 的宽度
  }

  // ============================================================
  // 【五种规格的布局 @Builder】
  //
  // 设计模式：每种规格一个 @Builder，在 build() 中根据 dimension 分支调用。
  // 所有规格共享同一套数据（@LocalStorageProp），只是展示密度不同。
  //
  // 左右分区交互设计（所有规格统一）：
  //   左侧区域（天气信息）.onClick → doAction()  → 打开主界面
  //   右侧区域（木鱼面板）.onClick → doKnock()   → 敲木鱼
  //
  // 关键布局技术：
  //   layoutWeight：按比例分配空间（如 layoutWeight(6) + layoutWeight(4) 即 60:40）
  //   linearGradient：线性渐变背景，colors 数组格式为 [['#颜色', 停止位置], ...]
  //   Blank()：在 Flex 布局中撑满剩余空间，实现"顶部固定 + 底部固定"效果
  // ============================================================

  /** 1×2：极简横条 —— 信息最少，只显示城市、温度、天气图标、高低温 */
  @Builder
  build1x2() {
    Row() {
      // 左侧：天气信息区域（占 60%），点击打开主界面
      Column() {
        Text(this.city)
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.8)')
        Text(`${this.conditionEmoji} ${this.temp}°`)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ top: 2 })
        Text(`↑${this.high}° ↓${this.low}°`)
          .fontSize(10)
          .fontColor('rgba(255,255,255,0.75)')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(6)          // Row 内按权重分配：左 6 + 右 4 = 60% : 40%
      .height('100%')
      .padding({ left: 14 })
      .onClick(() => this.doAction())

      // 分隔线：vertical=true 使 Divider 竖向排列
      Divider()
        .vertical(true)
        .strokeWidth(1)
        .color('rgba(255,255,255,0.2)')
        .height('65%')
        .alignSelf(ItemAlign.Center)   // 在 Row 中垂直居中对齐

      // 右侧：木鱼区域（占 40%），点击敲木鱼
      // 注意：@Builder 调用结果是 void，不能直接链式调用修饰符，
      // 必须用外层 Column 包裹，再对 Column 加修饰符。
      Column() {
        this.FishContent(36, 13)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(4)
      .height('100%')
      .onClick(() => this.doKnock())
    }
    .width('100%')
    .height('100%')
    // linearGradient：从 gradientStart（左上）渐变到 gradientEnd（右下），angle=135°
    .linearGradient({ angle: 135, colors: [[this.gradientStart, 0.0], [this.gradientEnd, 1.0]] })
    .borderRadius(16)
  }

  /** 2×2：标准方块 —— 增加空气质量 badge */
  @Builder
  build2x2() {
    Row() {
      Column() {
        Text(this.city)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.8)')
        Row() {
          Text(`${this.temp}°`)
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(this.conditionEmoji)
            .fontSize(26)
            .margin({ left: 6, top: 8 })
        }
        .margin({ top: 4 })
        Text(`↑${this.high}° ↓${this.low}°`)
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.85)')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(6)
      .height('100%')
      .padding({ left: 14 })
      .onClick(() => this.doAction())

      Divider()
        .vertical(true)
        .strokeWidth(1)
        .color('rgba(255,255,255,0.2)')
        .height('65%')
        .alignSelf(ItemAlign.Center)

      Column() {
        this.FishContent(44, 15)
        // 空气质量 badge：用 backgroundColor + borderRadius 模拟标签样式
        Text(this.airQuality)
          .fontSize(10)
          .fontColor('#FFFFFF')
          .backgroundColor('rgba(255,255,255,0.25)')
          .borderRadius(8)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(4)
      .height('100%')
      .onClick(() => this.doKnock())
    }
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [[this.gradientStart, 0.0], [this.gradientEnd, 1.0]] })
    .borderRadius(16)
  }

  /** 2×4：宽矩形 —— 左侧增加湿度和风力信息，Blank() 撑开剩余空间使其贴底显示 */
  @Builder
  build2x4() {
    Row() {
      Column() {
        Text(this.city)
          .fontSize(13)
          .fontColor('rgba(255,255,255,0.8)')
          .alignSelf(ItemAlign.Start)
        Text(`${this.temp}°`)
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ top: 2 })
        Text(`${this.conditionEmoji} ${this.condition}`)
          .fontSize(13)
          .fontColor('#FFFFFF')
        Text(`↑${this.high}° ↓${this.low}°`)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.8)')
          .margin({ top: 4 })
        // Blank() 在 Flex 列方向（Column 默认 FlexDirection.Column）
        // 会撑满剩余空间，使下面的湿度/风力信息贴近底部。
        Blank()
        Text(`💧 ${this.humidity}%  🌬️ ${this.windDir}${this.windScale}级`)
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.75)')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(55)
      .height('100%')
      .padding({ left: 14, right: 8, top: 14, bottom: 14 })
      .onClick(() => this.doAction())

      Divider()
        .vertical(true)
        .strokeWidth(1)
        .color('rgba(255,255,255,0.2)')
        .height('75%')
        .alignSelf(ItemAlign.Center)

      Column() {
        this.FishContent(52, 17)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(45)
      .height('100%')
      .onClick(() => this.doKnock())
    }
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [[this.gradientStart, 0.0], [this.gradientEnd, 1.0]] })
    .borderRadius(16)
  }

  /**
   * 4×4：大方块 —— 完整天气信息 + 4天预报 + 大尺寸木鱼面板
   *
   * justifyContent(FlexAlign.SpaceBetween)：
   * 让左侧 Column 的子元素在垂直方向上均匀分布，
   * 头部内容（城市/温度）靠近顶部，底部（预报）靠近底部，
   * 中间的 Blank() 负责撑开剩余空间。
   *
   * ForEach：ArkUI 的列表渲染指令，等价于 React 的 .map()。
   * 第一个参数是数组，第二个是渲染函数，每个元素对应一个子组件。
   * JSON.parse 将字符串还原为数组，as DailyCardItem[] 是 ArkTS 类型断言。
   */
  @Builder
  build4x4() {
    Row() {
      Column() {
        // 顶行：城市名 + 空气质量 badge，Blank() 撑开中间空隙实现两端对齐
        Row() {
          Text(this.city)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
          Blank()
          Text(this.airQuality)
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor('rgba(255,255,255,0.25)')
            .borderRadius(8)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        }
        .width('100%')

        // 温度 + 天气图标行
        Row() {
          Column() {
            Text(`${this.temp}°`)
              .fontSize(56)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .lineHeight(60)
            Text(`体感 ${this.feelsLike}°`)
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.8)')
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Column() {
            Text(this.conditionEmoji).fontSize(36)
            Text(this.condition)
              .fontSize(13)
              .fontColor('#FFFFFF')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .margin({ top: 8 })

        Text(`↑${this.high}° ↓${this.low}°`)
          .fontSize(13)
          .fontColor('rgba(255,255,255,0.85)')
          .alignSelf(ItemAlign.Start)
          .margin({ top: 4 })

        // 统计行：4个 StatItem 均分宽度（各 layoutWeight(1)）
        Row() {
          this.StatItem('💧', `${this.humidity}%`, '湿度')
          this.StatItem('🌬️', `${this.windScale}级`, this.windDir)
          this.StatItem('☀️', `${this.uvIndex}`, 'UV')
          this.StatItem('🍃', `${this.airIndex}`, 'AQI')
        }
        .width('100%')
        .backgroundColor('rgba(0,0,0,0.15)')
        .borderRadius(10)
        .padding({ top: 8, bottom: 8 })
        .margin({ top: 10 })

        // Blank 撑开剩余空间，使预报行贴底
        Blank()

        // 4天预报：ForEach 渲染，slice(0,4) 取前4条
        Row() {
          ForEach((JSON.parse(this.dailyJson) as DailyCardItem[]).slice(0, 4),
            (item: DailyCardItem) => {
              Column() {
                Text(item.date)
                  .fontSize(10)
                  .fontColor('rgba(255,255,255,0.7)')
                Text(`${item.high}°`)
                  .fontSize(13)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Medium)
                  .margin({ top: 4 })
                Text(`${item.low}°`)
                  .fontSize(11)
                  .fontColor('rgba(255,255,255,0.6)')
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
            })
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceBetween)   // 子元素在垂直方向两端对齐
      .layoutWeight(65)
      .height('100%')
      .padding(14)
      .onClick(() => this.doAction())

      Divider()
        .vertical(true)
        .strokeWidth(1)
        .color('rgba(255,255,255,0.2)')
        .height('85%')
        .alignSelf(ItemAlign.Center)

      Column() {
        this.FishContent(56, 19)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(35)
      .height('100%')
      .onClick(() => this.doKnock())
    }
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [[this.gradientStart, 0.0], [this.gradientEnd, 1.0]] })
    .borderRadius(16)
  }

  /**
   * 6×4：全量看板 —— 信息最丰富，左侧天气+5天预报，右侧木鱼+4小时预报
   *
   * 右侧 Column 内嵌套了两个区域：
   *   1. 木鱼面板（layoutWeight(1)，占据弹性剩余空间）
   *   2. 逐小时预报（固定内容，贴近底部）
   * 通过内层 Column 的 layoutWeight(1) + 外层 Column 的 height('100%')，
   * 实现木鱼区域自适应撑满、小时预报贴底的效果。
   */
  @Builder
  build6x4() {
    Row() {
      // 左侧：主天气信息 + 5天预报
      Column() {
        Text(this.city)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .alignSelf(ItemAlign.Start)

        Row() {
          Text(`${this.temp}°`)
            .fontSize(56)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .lineHeight(60)
          Text(this.conditionEmoji)
            .fontSize(36)
            .margin({ left: 8, top: 8 })
        }
        .margin({ top: 4 })

        Text(`${this.condition}  体感${this.feelsLike}°`)
          .fontSize(13)
          .fontColor('rgba(255,255,255,0.85)')
        Text(`↑${this.high}° ↓${this.low}°`)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.8)')
          .margin({ top: 4 })

        Row() {
          this.StatItem('💧', `${this.humidity}%`, '湿度')
          this.StatItem('🌬️', `${this.windScale}级`, '风力')
          this.StatItem('🍃', `${this.airIndex}`, 'AQI')
        }
        .width('100%')
        .backgroundColor('rgba(0,0,0,0.15)')
        .borderRadius(10)
        .padding({ top: 8, bottom: 8 })
        .margin({ top: 10 })

        Blank()

        // 5天预报
        Row() {
          ForEach((JSON.parse(this.dailyJson) as DailyCardItem[]).slice(0, 5),
            (item: DailyCardItem) => {
              Column() {
                Text(item.date)
                  .fontSize(10)
                  .fontColor('rgba(255,255,255,0.7)')
                Text(item.condition)
                  .fontSize(9)
                  .fontColor('rgba(255,255,255,0.6)')
                  .margin({ top: 2 })
                Text(`${item.high}°`)
                  .fontSize(12)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Medium)
                  .margin({ top: 3 })
                Text(`${item.low}°`)
                  .fontSize(10)
                  .fontColor('rgba(255,255,255,0.6)')
                  .margin({ top: 1 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
            })
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(65)
      .height('100%')
      .padding(16)
      .onClick(() => this.doAction())

      Divider()
        .vertical(true)
        .strokeWidth(1)
        .color('rgba(255,255,255,0.2)')
        .height('85%')
        .alignSelf(ItemAlign.Center)

      // 右侧：木鱼 + 4小时预报，整体点击触发敲木鱼
      Column() {
        // 木鱼面板撑满上方弹性空间
        Column() {
          this.FishContent(60, 20)
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)     // 占据除小时预报外的所有剩余空间
        .width('100%')

        Divider()
          .strokeWidth(1)
          .color('rgba(255,255,255,0.2)')
          .margin({ top: 6, bottom: 6 })

        // 4小时预报（贴底展示）
        Row() {
          ForEach((JSON.parse(this.hourlyJson) as HourlyCardItem[]).slice(0, 4),
            (item: HourlyCardItem) => {
              Column() {
                Text(item.hour)
                  .fontSize(9)
                  .fontColor('rgba(255,255,255,0.65)')
                Text(`${item.temp}°`)
                  .fontSize(12)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Medium)
                  .margin({ top: 3 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
            })
        }
        .width('100%')
      }
      .layoutWeight(35)
      .height('100%')
      .padding({ top: 14, bottom: 14, left: 8, right: 14 })
      .onClick(() => this.doKnock())
    }
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [[this.gradientStart, 0.0], [this.gradientEnd, 1.0]] })
    .borderRadius(16)
  }

  /**
   * build() — ArkUI 组件必须实现的根渲染方法
   *
   * 根据 dimension 的值选择渲染哪个布局 @Builder。
   * dimension 由 FormAbility 注入，对应值：
   *   1 = 1×2  |  2 = 2×2  |  4 = 2×4  |  5 = 4×4  |  6 = 6×4
   *
   * 为什么不用 switch-case？
   * ArkUI 的 build() 方法对语法有限制，推荐 if/else 做条件渲染。
   * switch-case 在某些 ArkTS 版本中 build() 里使用会有警告。
   *
   * 为什么用 @Builder 而不是直接在 build() 里写所有布局？
   * build() 职责单一：只做分支路由。各规格的布局细节封装在各自的 @Builder 中，
   * 符合单一职责原则，也让每个布局函数独立可读。
   */
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
      this.build2x2();   // 兜底：未知规格默认渲染 2×2
    }
  }
}

/**
 * HourlyCardItem / DailyCardItem — 卡片内解析 JSON 所用的本地接口
 *
 * 这两个 interface 定义在文件底部而非顶部，是因为：
 *   1. 它们只在 WidgetCard 的 @Builder 中使用，作用域明确
 *   2. ArkTS 允许 interface 在使用处之后声明（类型提升）
 *
 * 注意：这里必须用 interface，不能用 WeatherData.ets 中的 HourlyItem/DailyItem，
 * 因为卡片环境对 import 路径有一定限制，且卡片内的解析只需要部分字段。
 * （当然也可以 import 并复用，只是这里为了卡片文件的独立性而本地声明）
 */
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
