# 🚀 Android Migration Guide: KaptionedV2

This document provides comprehensive instructions for implementing the KaptionedV2 iOS app in native Android. This is a professional-grade video subtitle burning application that uses native Android frameworks instead of FFmpeg, following the same approach used by apps like CapCut, InShot, and VLLO.

## 📋 Project Overview

**Core Functionality:**
- Professional subtitle burning with native Android frameworks (MediaCodec + OpenGL ES)
- Advanced text styling (font, color, stroke, shadow, background)
- Karaoke subtitle effects with word-by-word highlighting
- Multi-line text support with explicit line breaks
- WYSIWYG preview-export consistency
- Project management with thumbnail generation
- Subscription system with RevenueCat integration
- Transcription API integration (Whisper/OpenAI)

**Key Technical Challenge:** Achieving perfect WYSIWYG (What You See Is What You Get) consistency between the editor preview and exported video.

## 🏗️ Architecture Overview

### Core Components to Implement

1. **Video Processing Pipeline** - MediaCodec + OpenGL ES for subtitle burning
2. **Text Rendering System** - Canvas + Paint for text styling and effects
3. **Karaoke Animation Engine** - Frame-accurate word timing with animations
4. **Project Management** - Room Database for persistence
5. **Subscription System** - RevenueCat integration with encrypted storage
6. **Transcription Service** - API integration for automatic subtitle generation
7. **Configuration System** - Remote config loading and caching

## 🎯 Critical Implementation Areas

### 1. Native Subtitle Burning Pipeline

**Android Equivalent of iOS AVFoundation + Core Animation:**

```kotlin
// Core video processing pipeline
class VideoEditor {
    private val mediaCodec: MediaCodec
    private val mediaMuxer: MediaMuxer
    private val openGLRenderer: OpenGLRenderer
    
    fun burnSubtitles(
        inputVideo: Uri,
        textBoxes: List<TextBox>,
        outputPath: String,
        progressCallback: (Float) -> Unit
    ): Result<String> {
        // 1. Extract video frames using MediaCodec
        // 2. Render text overlays using OpenGL ES
        // 3. Composite frames with text
        // 4. Encode final video using MediaCodec
    }
}
```

**Key Technical Requirements:**
- Use `MediaCodec` for video decoding/encoding (30fps)
- Use `OpenGL ES` for text rendering and compositing
- Implement frame-accurate timing with `MediaCodec.BufferInfo`
- Handle hardware acceleration and fallback to software rendering
- Support multiple video formats (MP4, MOV, AVI)

### 2. Text Rendering System

**Android Equivalent of iOS Core Graphics:**

```kotlin
data class TextBox(
    val id: String = UUID.randomUUID().toString(),
    val text: String = "",
    val fontSize: Float = 20f,
    val fontColor: Int = Color.BLACK,
    val strokeColor: Int = Color.TRANSPARENT,
    val strokeWidth: Float = 0f,
    val shadowColor: Int = Color.BLACK,
    val shadowRadius: Float = 0f,
    val shadowX: Float = 0f,
    val shadowY: Float = 0f,
    val shadowOpacity: Float = 0.5f,
    val bgColor: Int = Color.WHITE,
    val backgroundPadding: Float = 8f,
    val cornerRadius: Float = 0f,
    val timeRange: ClosedRange<Double> = 0.0..3.0,
    val offset: PointF = PointF(0f, 0f),
    
    // Karaoke properties
    val isKaraokePreset: Boolean = false,
    val karaokeType: KaraokeType? = null,
    val highlightColor: Int? = null,
    val wordBGColor: Int? = null,
    val activeWordScale: Float = 1.2f,
    val wordTimings: List<WordWithTiming>? = null,
    val presetName: String? = null
)

data class WordWithTiming(
    val id: String = UUID.randomUUID().toString(),
    val text: String,
    val start: Double,
    val end: Double
)

enum class KaraokeType(val value: String) {
    WORD("Word"),
    WORDBG("WordBG"),
    WORD_AND_SCALE("WordAndScale")
}
```

**Text Rendering Implementation:**

```kotlin
class TextRenderer {
    fun renderText(
        canvas: Canvas,
        textBox: TextBox,
        currentTime: Double,
        videoSize: Size
    ) {
        val paint = Paint().apply {
            isAntiAlias = true
            textSize = textBox.fontSize
            color = textBox.fontColor
            strokeWidth = textBox.strokeWidth
            strokeColor = textBox.strokeColor
            setShadowLayer(
                textBox.shadowRadius,
                textBox.shadowX,
                textBox.shadowY,
                Color.argb(
                    (textBox.shadowOpacity * 255).toInt(),
                    Color.red(textBox.shadowColor),
                    Color.green(textBox.shadowColor),
                    Color.blue(textBox.shadowColor)
                )
            )
        }
        
        if (textBox.isKaraokePreset && textBox.wordTimings != null) {
            renderKaraokeText(canvas, textBox, paint, currentTime)
        } else {
            renderRegularText(canvas, textBox, paint)
        }
    }
    
    private fun renderKaraokeText(
        canvas: Canvas,
        textBox: TextBox,
        paint: Paint,
        currentTime: Double
    ) {
        // Implement karaoke word-by-word highlighting
        // Handle different karaoke types (word, wordbg, wordAndScale)
        // Apply frame-accurate timing animations
    }
}
```

### 3. WYSIWYG Consistency System

**Critical Challenge:** Ensure preview and export render identically.

**Solution:**
- Use identical text rendering algorithms in both preview and export
- Implement coordinate system normalization
- Apply consistent spacing calibration
- Use same font metrics and text layout calculations

```kotlin
class WYSIWYGTextRenderer {
    companion object {
        // Calibration multipliers for export vs preview spacing
        private const val KARAOKE_WORD_SPACING_MULTIPLIER = 3.0f
        private const val KARAOKE_WORDBG_SPACING_MULTIPLIER = 1.5f
    }
    
    fun renderForPreview(textBox: TextBox, canvas: Canvas): Unit {
        // Use preview spacing values
        renderText(textBox, canvas, isPreview = true)
    }
    
    fun renderForExport(textBox: TextBox, canvas: Canvas): Unit {
        // Apply calibration multipliers for export
        val calibratedSpacing = when (textBox.karaokeType) {
            KaraokeType.WORD, KaraokeType.WORD_AND_SCALE -> 
                textBox.spacing * KARAOKE_WORD_SPACING_MULTIPLIER
            KaraokeType.WORDBG -> 
                textBox.spacing * KARAOKE_WORDBG_SPACING_MULTIPLIER
            else -> textBox.spacing
        }
        renderText(textBox.copy(spacing = calibratedSpacing), canvas, isPreview = false)
    }
}
```

### 4. Karaoke Animation Engine

**Frame-Accurate Timing Implementation:**

```kotlin
class KaraokeAnimationEngine {
    fun createWordAnimations(
        wordTimings: List<WordWithTiming>,
        karaokeType: KaraokeType,
        highlightColor: Int,
        activeWordScale: Float = 1.2f
    ): List<WordAnimation> {
        return wordTimings.map { word ->
            WordAnimation(
                word = word,
                startTime = word.start,
                endTime = word.end,
                highlightColor = highlightColor,
                scale = if (karaokeType == KaraokeType.WORD_AND_SCALE) activeWordScale else 1.0f
            )
        }
    }
}

data class WordAnimation(
    val word: WordWithTiming,
    val startTime: Double,
    val endTime: Double,
    val highlightColor: Int,
    val scale: Float
) {
    fun isActive(currentTime: Double): Boolean {
        return currentTime >= startTime && currentTime < endTime
    }
    
    fun getProgress(currentTime: Double): Float {
        if (currentTime < startTime) return 0f
        if (currentTime >= endTime) return 1f
        return ((currentTime - startTime) / (endTime - startTime)).toFloat()
    }
}
```

### 5. Multi-Line Text Support

**Explicit Line Break Handling:**

```kotlin
class MultiLineTextRenderer {
    fun organizeWordsIntoLines(
        originalText: String,
        words: List<WordWithTiming>
    ): List<List<WordWithTiming>> {
        val textLines = originalText.split("\n")
        
        if (textLines.size <= 1) {
            return listOf(words)
        }
        
        val result = mutableListOf<List<WordWithTiming>>()
        var wordIndex = 0
        
        for (textLine in textLines) {
            val lineWords = textLine.split("\\s+".toRegex())
            val currentLineWords = mutableListOf<WordWithTiming>()
            
            for (word in lineWords) {
                if (wordIndex < words.size) {
                    currentLineWords.add(words[wordIndex])
                    wordIndex++
                }
            }
            
            if (currentLineWords.isNotEmpty()) {
                result.add(currentLineWords)
            }
        }
        
        return result.ifEmpty { listOf(words) }
    }
    
    fun renderMultiLineKaraoke(
        canvas: Canvas,
        textBox: TextBox,
        currentTime: Double
    ) {
        val lines = organizeWordsIntoLines(textBox.text, textBox.wordTimings ?: emptyList())
        val hasMultipleLines = lines.size > 1
        
        var yOffset = 0f
        for (line in lines) {
            val lineHeight = renderKaraokeLine(canvas, line, textBox, currentTime, yOffset)
            yOffset += lineHeight + textBox.lineSpacing
        }
    }
}
```

### 6. Project Management with Room Database

**Database Schema:**

```kotlin
@Entity(tableName = "projects")
data class ProjectEntity(
    @PrimaryKey val id: String,
    val url: String,
    val createdAt: Long,
    val appliedTools: String? = null,
    val thumbnailPath: String? = null
)

@Entity(
    tableName = "text_boxes",
    foreignKeys = [
        ForeignKey(
            entity = ProjectEntity::class,
            parentColumns = ["id"],
            childColumns = ["projectId"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class TextBoxEntity(
    @PrimaryKey val id: String,
    val projectId: String,
    val text: String,
    val fontSize: Float,
    val fontColor: String, // Hex color
    val strokeColor: String,
    val strokeWidth: Float,
    val shadowColor: String,
    val shadowRadius: Float,
    val shadowX: Float,
    val shadowY: Float,
    val shadowOpacity: Float,
    val bgColor: String,
    val backgroundPadding: Float,
    val cornerRadius: Float,
    val lowerTime: Double,
    val upperTime: Double,
    val offsetX: Float,
    val offsetY: Float,
    
    // Karaoke properties
    val isKaraokePreset: Boolean,
    val karaokeType: String?,
    val highlightColor: String?,
    val wordBGColor: String?,
    val activeWordScale: Float,
    val wordTimingsData: String?, // JSON encoded
    val presetName: String?
)

@Database(
    entities = [ProjectEntity::class, TextBoxEntity::class],
    version = 1
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun projectDao(): ProjectDao
    abstract fun textBoxDao(): TextBoxDao
}
```

### 7. Subscription System with RevenueCat

**Encrypted Storage Implementation:**

```kotlin
class SubscriptionManager @Inject constructor(
    private val context: Context,
    private val revenueCatManager: RevenueCatManager
) {
    private val encryptedPreferences: EncryptedSharedPreferences
    private val deviceKey: String
    
    init {
        // Generate device-specific encryption key
        deviceKey = generateDeviceKey()
        encryptedPreferences = createEncryptedPreferences()
    }
    
    private fun generateDeviceKey(): String {
        val deviceId = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ANDROID_ID
        )
        val packageName = context.packageName
        val buildManufacturer = Build.MANUFACTURER
        
        return "$deviceId:$packageName:$buildManufacturer".hash()
    }
    
    fun canCreateNewVideo(): Boolean {
        val status = getSubscriptionStatus()
        return when (status.tier) {
            SubscriptionTier.UNLIMITED -> true
            else -> status.videosCreated < status.tier.maxVideos
        }
    }
    
    fun recordVideoCreation() {
        val status = getSubscriptionStatus()
        val newStatus = status.copy(videosCreated = status.videosCreated + 1)
        saveSubscriptionStatus(newStatus)
    }
}

enum class SubscriptionTier(val displayName: String, val maxVideos: Int) {
    FREE("Free", 1),
    PRO("Pro", 10),
    UNLIMITED("Unlimited", Int.MAX_VALUE)
}

data class SubscriptionStatus(
    val tier: SubscriptionTier = SubscriptionTier.FREE,
    val videosCreated: Int = 0,
    val subscriptionExpiryDate: Long? = null,
    val isActive: Boolean = true
)
```

### 8. Transcription API Integration

**Whisper/OpenAI Integration:**

```kotlin
class TranscriptionService @Inject constructor(
    private val apiService: TranscriptionApiService,
    private val audioExtractor: AudioExtractor
) {
    suspend fun transcribeVideo(
        videoUri: Uri,
        language: String = "en",
        maxWordsPerLine: Int = 1
    ): Result<List<TextBox>> {
        return try {
            // Extract audio from video
            val audioFile = audioExtractor.extractAudio(videoUri)
            
            // Upload to transcription API
            val response = apiService.transcribe(
                audioFile = audioFile.asRequestBody("audio/m4a".toMediaType()),
                language = language,
                maxWordsPerLine = maxWordsPerLine
            )
            
            // Convert response to TextBox models
            val textBoxes = response.segments.map { segment ->
                TextBox(
                    text = segment.sentence,
                    timeRange = segment.words.first().start..segment.words.last().end,
                    wordTimings = segment.words.map { word ->
                        WordWithTiming(
                            text = word.word,
                            start = word.start,
                            end = word.end
                        )
                    },
                    presetName = "Modern White"
                )
            }
            
            Result.success(textBoxes)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

interface TranscriptionApiService {
    @Multipart
    @POST("transcribe")
    suspend fun transcribe(
        @Part audioFile: RequestBody,
        @Part("primary_lang") language: RequestBody,
        @Part("max_words_per_line") maxWordsPerLine: RequestBody
    ): TranscriptionResponse
}

data class TranscriptionResponse(
    val segments: List<TranscriptionSegment>
)

data class TranscriptionSegment(
    val sentence: String,
    val words: List<TranscriptionWord>
)

data class TranscriptionWord(
    val word: String,
    val start: Double,
    val end: Double,
    val probability: Double
)
```

### 9. Configuration System

**Remote Configuration Management:**

```kotlin
class ConfigurationManager @Inject constructor(
    private val apiService: ConfigApiService,
    private val preferences: SharedPreferences
) {
    private val _config = MutableStateFlow(AppConfig.default)
    val config: StateFlow<AppConfig> = _config.asStateFlow()
    
    suspend fun loadConfiguration() {
        try {
            val remoteConfig = apiService.getConfiguration()
            val mergedConfig = mergeConfigs(AppConfig.default, remoteConfig)
            _config.value = mergedConfig
            saveToCache(mergedConfig)
        } catch (e: Exception) {
            // Load from cache on failure
            loadFromCache()
        }
    }
    
    fun getTranscriptionUrl(): String {
        return "${config.value.api.baseUrl}${config.value.transcription.endpoint}"
    }
    
    fun getDefaultLanguage(): String {
        return config.value.transcription.defaultLanguage
    }
    
    fun isKaraokeEnabled(): Boolean {
        return config.value.features.enableKaraoke
    }
}

data class AppConfig(
    val api: ApiConfig,
    val transcription: TranscriptionConfig,
    val features: FeatureConfig,
    val revenueCat: RevenueCatConfig,
    val paywall: PaywallConfig,
    val subscription: SubscriptionConfig
) {
    companion object {
        val default = AppConfig(
            api = ApiConfig.default,
            transcription = TranscriptionConfig.default,
            features = FeatureConfig.default,
            revenueCat = RevenueCatConfig.default,
            paywall = PaywallConfig.default,
            subscription = SubscriptionConfig.default
        )
    }
}
```

## 🎨 UI Implementation

### Main Architecture Components

```kotlin
// Main Activity
class MainActivity : AppCompatActivity() {
    private val viewModel: MainViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        // Initialize configuration
        lifecycleScope.launch {
            viewModel.loadConfiguration()
        }
        
        // Setup navigation
        setupNavigation()
    }
}

// Main ViewModel
@HiltViewModel
class MainViewModel @Inject constructor(
    private val configurationManager: ConfigurationManager,
    private val subscriptionManager: SubscriptionManager
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(MainUiState())
    val uiState: StateFlow<MainUiState> = _uiState.asStateFlow()
    
    fun loadConfiguration() {
        viewModelScope.launch {
            configurationManager.loadConfiguration()
        }
    }
    
    fun createNewProject() {
        if (!subscriptionManager.canCreateNewVideo()) {
            _uiState.value = _uiState.value.copy(showUpgradeDialog = true)
            return
        }
        
        // Navigate to editor
        _uiState.value = _uiState.value.copy(navigateToEditor = true)
    }
}

data class MainUiState(
    val projects: List<ProjectEntity> = emptyList(),
    val isLoading: Boolean = false,
    val showUpgradeDialog: Boolean = false,
    val navigateToEditor: Boolean = false
)
```

### Video Editor Screen

```kotlin
@AndroidEntryPoint
class VideoEditorActivity : AppCompatActivity() {
    private val viewModel: VideoEditorViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_video_editor)
        
        setupVideoPlayer()
        setupTextEditor()
        setupTimeline()
    }
    
    private fun setupVideoPlayer() {
        // Implement ExoPlayer for video playback
        // Add text overlay rendering
        // Handle seek events for karaoke preview
    }
    
    private fun setupTextEditor() {
        // Implement text editing UI
        // Style controls (font, color, stroke, shadow)
        // Karaoke preset selection
    }
    
    private fun setupTimeline() {
        // Implement timeline with text box positioning
        // Drag and drop functionality
        // Time range editing
    }
}
```

## 🔧 Technical Implementation Details

### 1. Video Processing Pipeline

**MediaCodec Implementation:**

```kotlin
class VideoProcessor {
    private var decoder: MediaCodec? = null
    private var encoder: MediaCodec? = null
    private var muxer: MediaMuxer? = null
    
    fun processVideo(
        inputPath: String,
        outputPath: String,
        textBoxes: List<TextBox>,
        progressCallback: (Float) -> Unit
    ): Result<String> {
        return try {
            // Setup decoder
            setupDecoder(inputPath)
            
            // Setup encoder
            setupEncoder(outputPath)
            
            // Setup muxer
            setupMuxer(outputPath)
            
            // Process frames
            processFrames(textBoxes, progressCallback)
            
            Result.success(outputPath)
        } catch (e: Exception) {
            Result.failure(e)
        } finally {
            cleanup()
        }
    }
    
    private fun processFrames(
        textBoxes: List<TextBox>,
        progressCallback: (Float) -> Unit
    ) {
        val bufferInfo = MediaCodec.BufferInfo()
        var frameIndex = 0
        val totalFrames = calculateTotalFrames()
        
        while (true) {
            val outputBufferIndex = decoder?.dequeueOutputBuffer(bufferInfo, TIMEOUT_US)
            
            when (outputBufferIndex) {
                MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    // Handle format change
                }
                MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED -> {
                    // Handle buffer change
                }
                MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    // Try again later
                }
                else -> {
                    if (outputBufferIndex != null && outputBufferIndex >= 0) {
                        // Process frame
                        val currentTime = bufferInfo.presentationTimeUs / 1_000_000.0
                        val frame = extractFrame(outputBufferIndex)
                        val frameWithText = renderTextOverlay(frame, textBoxes, currentTime)
                        encodeFrame(frameWithText, bufferInfo)
                        
                        frameIndex++
                        progressCallback(frameIndex.toFloat() / totalFrames)
                    }
                }
            }
        }
    }
}
```

### 2. OpenGL ES Text Rendering

**Shader Implementation:**

```kotlin
class TextRenderer {
    private val vertexShader = """
        attribute vec4 aPosition;
        attribute vec2 aTexCoord;
        varying vec2 vTexCoord;
        
        void main() {
            gl_Position = aPosition;
            vTexCoord = aTexCoord;
        }
    """.trimIndent()
    
    private val fragmentShader = """
        precision mediump float;
        uniform sampler2D uTexture;
        uniform vec4 uColor;
        uniform vec4 uStrokeColor;
        uniform float uStrokeWidth;
        uniform vec4 uShadowColor;
        uniform float uShadowRadius;
        uniform vec2 uShadowOffset;
        
        varying vec2 vTexCoord;
        
        void main() {
            vec4 texColor = texture2D(uTexture, vTexCoord);
            vec4 finalColor = mix(uStrokeColor, uColor, texColor.r);
            gl_FragColor = finalColor;
        }
    """.trimIndent()
    
    fun renderText(
        text: String,
        x: Float,
        y: Float,
        fontSize: Float,
        color: Int,
        strokeColor: Int,
        strokeWidth: Float,
        shadowColor: Int,
        shadowRadius: Float,
        shadowOffset: PointF
    ) {
        // Generate texture from text
        val texture = generateTextTexture(text, fontSize, color, strokeColor, strokeWidth)
        
        // Apply shadow
        if (shadowRadius > 0) {
            renderShadow(texture, shadowColor, shadowRadius, shadowOffset)
        }
        
        // Render main text
        renderTexture(texture, x, y)
    }
}
```

### 3. Frame-Accurate Timing

**Timing Implementation:**

```kotlin
class FrameTimingManager {
    private val frameRate = 30.0
    private val frameDuration = 1.0 / frameRate
    
    fun calculateFrameTime(frameIndex: Int): Double {
        return frameIndex * frameDuration
    }
    
    fun isTextBoxVisible(textBox: TextBox, currentTime: Double): Boolean {
        return currentTime >= textBox.timeRange.start && currentTime <= textBox.timeRange.end
    }
    
    fun getKaraokeProgress(word: WordWithTiming, currentTime: Double): Float {
        if (currentTime < word.start) return 0f
        if (currentTime >= word.end) return 1f
        return ((currentTime - word.start) / (word.end - word.start)).toFloat()
    }
}
```

## 🧪 Testing Strategy

### 1. WYSIWYG Consistency Testing

```kotlin
class WYSIWYGConsistencyTest {
    @Test
    fun testPreviewExportConsistency() {
        val textBox = createTestTextBox()
        
        // Render for preview
        val previewCanvas = createPreviewCanvas()
        val previewRenderer = WYSIWYGTextRenderer()
        previewRenderer.renderForPreview(textBox, previewCanvas)
        val previewBitmap = previewCanvas.bitmap
        
        // Render for export
        val exportCanvas = createExportCanvas()
        previewRenderer.renderForExport(textBox, exportCanvas)
        val exportBitmap = exportCanvas.bitmap
        
        // Compare bitmaps
        assertBitmapsEqual(previewBitmap, exportBitmap, tolerance = 0.01f)
    }
}
```

### 2. Karaoke Timing Tests

```kotlin
class KaraokeTimingTest {
    @Test
    fun testWordTimingAccuracy() {
        val wordTimings = listOf(
            WordWithTiming("Hello", 0.0, 0.5),
            WordWithTiming("World", 0.5, 1.0)
        )
        
        val engine = KaraokeAnimationEngine()
        val animations = engine.createWordAnimations(wordTimings, KaraokeType.WORD, Color.YELLOW)
        
        // Test timing accuracy
        assertFalse(animations[0].isActive(0.0))
        assertTrue(animations[0].isActive(0.25))
        assertFalse(animations[0].isActive(0.5))
        assertTrue(animations[1].isActive(0.75))
    }
}
```

## 🚀 Performance Optimization

### 1. Hardware Acceleration

```kotlin
class HardwareAcceleratedRenderer {
    private val eglContext: EGLContext
    private val textureCache: LruCache<String, Int>
    
    fun renderFrame(
        frame: Bitmap,
        textBoxes: List<TextBox>,
        currentTime: Double
    ): Bitmap {
        // Use OpenGL ES for hardware-accelerated rendering
        // Cache textures for better performance
        // Use vertex buffer objects for efficient rendering
    }
}
```

### 2. Memory Management

```kotlin
class MemoryManager {
    private val bitmapPool = BitmapPool()
    
    fun recycleBitmap(bitmap: Bitmap) {
        bitmapPool.recycle(bitmap)
    }
    
    fun obtainBitmap(width: Int, height: Int): Bitmap {
        return bitmapPool.obtain(width, height)
    }
}
```

## 📱 Android-Specific Considerations

### 1. Permission Handling

```kotlin
class PermissionManager {
    private val requiredPermissions = arrayOf(
        Manifest.permission.READ_EXTERNAL_STORAGE,
        Manifest.permission.WRITE_EXTERNAL_STORAGE
    )
    
    fun checkAndRequestPermissions(activity: Activity) {
        if (!hasPermissions(activity)) {
            ActivityCompat.requestPermissions(activity, requiredPermissions, PERMISSION_REQUEST_CODE)
        }
    }
}
```

### 2. File Management

```kotlin
class FileManager {
    fun createVideoPath(): String {
        val fileName = "video_${System.currentTimeMillis()}.mp4"
        return File(context.getExternalFilesDir(Environment.DIRECTORY_MOVIES), fileName).absolutePath
    }
    
    fun saveThumbnail(projectId: String, bitmap: Bitmap) {
        val file = File(context.cacheDir, "thumb_$projectId.jpg")
        file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, 90, it) }
    }
}
```

### 3. Background Processing

```kotlin
class VideoExportWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {
    
    override suspend fun doWork(): Result {
        return try {
            val inputPath = inputData.getString(KEY_INPUT_PATH) ?: return Result.failure()
            val outputPath = inputData.getString(KEY_OUTPUT_PATH) ?: return Result.failure()
            val textBoxesJson = inputData.getString(KEY_TEXT_BOXES) ?: return Result.failure()
            
            val textBoxes = Gson().fromJson(textBoxesJson, Array<TextBox>::class.java).toList()
            
            val processor = VideoProcessor()
            processor.processVideo(inputPath, outputPath, textBoxes) { progress ->
                setProgress(workDataOf("progress" to progress))
            }
            
            Result.success()
        } catch (e: Exception) {
            Result.failure()
        }
    }
}
```

## 🔐 Security Implementation

### 1. Encrypted Storage

```kotlin
class EncryptedStorage {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()
    
    private val encryptedPreferences = EncryptedSharedPreferences.create(
        context,
        "secure_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )
    
    fun saveSubscriptionData(data: String) {
        encryptedPreferences.edit().putString("subscription_data", data).apply()
    }
    
    fun getSubscriptionData(): String? {
        return encryptedPreferences.getString("subscription_data", null)
    }
}
```

### 2. Device Fingerprinting

```kotlin
class DeviceFingerprint {
    fun generateFingerprint(): String {
        val deviceId = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ANDROID_ID
        )
        val packageName = context.packageName
        val buildFingerprint = Build.FINGERPRINT
        
        return "$deviceId:$packageName:$buildFingerprint".hash()
    }
}
```

## 📊 Analytics and Monitoring

### 1. Performance Monitoring

```kotlin
class PerformanceMonitor {
    fun trackExportTime(duration: Long) {
        FirebasePerformance.getInstance().newTrace("video_export").apply {
            putMetric("duration_ms", duration)
            stop()
        }
    }
    
    fun trackMemoryUsage() {
        val runtime = Runtime.getRuntime()
        val usedMemory = runtime.totalMemory() - runtime.freeMemory()
        FirebasePerformance.getInstance().newTrace("memory_usage").apply {
            putMetric("used_mb", usedMemory / 1024 / 1024)
            stop()
        }
    }
}
```

## 🎯 Critical Success Factors

### 1. WYSIWYG Consistency
- **Must Achieve:** Perfect pixel-perfect match between preview and export
- **Implementation:** Use identical rendering algorithms, coordinate normalization, spacing calibration
- **Testing:** Automated bitmap comparison with tolerance thresholds

### 2. Frame-Accurate Timing
- **Must Achieve:** Subtitle timing accurate to 1/30th second (30fps)
- **Implementation:** MediaCodec timing, precise word timing calculations
- **Testing:** Frame-by-frame analysis of exported videos

### 3. Performance Optimization
- **Must Achieve:** Smooth 30fps rendering on mid-range devices
- **Implementation:** Hardware acceleration, texture caching, memory management
- **Testing:** Performance profiling on various device specifications

### 4. Memory Management
- **Must Achieve:** Stable memory usage during long video processing
- **Implementation:** Bitmap pooling, texture recycling, garbage collection optimization
- **Testing:** Memory leak detection, stress testing with large videos

### 5. Cross-Device Compatibility
- **Must Achieve:** Consistent behavior across Android versions and device manufacturers
- **Implementation:** Fallback rendering paths, device-specific optimizations
- **Testing:** Testing on various Android versions and device types

## 🚀 Deployment Checklist

### Pre-Launch Testing
- [ ] WYSIWYG consistency verified across all text styles
- [ ] Karaoke timing accuracy tested with frame analysis
- [ ] Performance tested on low-end devices
- [ ] Memory usage optimized and stable
- [ ] Subscription system tested end-to-end
- [ ] Transcription API integration tested
- [ ] Error handling and recovery tested
- [ ] Accessibility features implemented
- [ ] Privacy policy and terms of service updated

### Store Preparation
- [ ] App store listing with screenshots and videos
- [ ] Privacy policy and data handling documentation
- [ ] RevenueCat products configured
- [ ] Analytics and crash reporting configured
- [ ] Beta testing completed
- [ ] Legal review completed

This migration guide provides a comprehensive roadmap for implementing the KaptionedV2 app in native Android while maintaining the same professional-grade quality and WYSIWYG consistency as the iOS version.
