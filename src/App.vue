<template>
  <div id="app">
    <KafkaMessageSender />
  </div>
</template>

<script>
import KafkaMessageSender from './components/KafkaMessageSender.vue'

export default {
  name: 'App',
  components: {
    KafkaMessageSender
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
